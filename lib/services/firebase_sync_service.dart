import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

/// Manages bidirectional synchronization between local SQLite and Firebase.
///
/// Strategy:
/// - Offline-first: all writes go to SQLite first.
/// - When online, this service pushes dirty local records to Firebase and
///   pulls changes from Firebase into SQLite.
/// - Conflict resolution: Last-Write-Wins based on [updated_at] timestamp.
class FirebaseSyncService {
  static final FirebaseSyncService instance = FirebaseSyncService._();
  FirebaseSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Tables that participate in sync (order matters: parents before children)
  static const List<String> _syncTables = [
    'products',
    'purchase_history',
    'purchase_orders',
    'purchase_order_items',
    'suppliers',
    'customers',
    'settings',
    'daily_sales_sheets',
    'sales',
    'sale_items',
    'sales_returns',
    'sales_return_items',
    'expenses',
    'customer_payments',
    'supplier_payments',
  ];

  /// Root Firestore path for this table
  CollectionReference _col(String table) {
    return _firestore.collection(table);
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Performs a full bidirectional sync. Call this when network is available.
  Future<SyncResult> sync({bool forcePull = false}) async {

    int pushed = 0;
    int pulled = 0;
    final errors = <String>[];

    final db = await DatabaseHelper.instance.database;
    final lastSync = await _getLastSyncTimestamp();

    for (final table in _syncTables) {
      try {
        pushed += await _push(db, table, lastSync);
        pulled += await _pull(db, table, forcePull ? 0 : lastSync, forcePull: forcePull);
      } catch (e) {
        errors.add('$table: $e');
      }
    }

    await _setLastSyncTimestamp(DateTime.now().millisecondsSinceEpoch);
    return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
  }

  // ─── Push: Local → Firebase ──────────────────────────────────────────────

  Future<int> _push(dynamic db, String table, int lastSync) async {
    // Fetch rows modified after the last sync (or all if first sync)
    List<Map<String, dynamic>> rows;
    try {
      if (lastSync == 0) {
        rows = await db.query(table);
      } else {
        rows = await db.query(
          table,
          where: 'updated_at > ? OR sync_id IS NULL',
          whereArgs: [lastSync],
        );
      }
    } catch (_) {
      // Fallback: column may not exist yet — push everything
      rows = await db.query(table);
    }

    if (rows.isEmpty) return 0;

    var batch = _firestore.batch();
    int count = 0;

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);

      // Assign a sync_id if the record doesn't have one yet
      if (row['sync_id'] == null) {
        row['sync_id'] = _uuid.v4();
        // settings table uses 'key' as PK; all others use 'id'
        final pkCol = (table == 'settings') ? 'key' : 'id';
        await db.update(
          table,
          {'sync_id': row['sync_id'], 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: '$pkCol = ?',
          whereArgs: [row[pkCol]],
        );
      }

      final docRef = _col(table).doc(row['sync_id'] as String);
      batch.set(docRef, _toFirestoreMap(row), SetOptions(merge: true));
      count++;

      // Firestore batches are limited to 500 ops — commit and reset
      if (count % 490 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    // Commit any remaining ops in the batch
    if (count % 490 != 0) {
      await batch.commit();
    }
    return count;
  }

  // ─── Pull: Firebase → Local ──────────────────────────────────────────────

  Future<int> _pull(dynamic db, String table, int lastSync, {bool forcePull = false}) async {
    Query query = _col(table);
    if (lastSync > 0) {
      query = query.where('updated_at', isGreaterThan: lastSync);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return 0;

    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['sync_id'] = doc.id; // ensure sync_id is set
      data['is_deleted'] = (data['is_deleted'] as int?) ?? 0;

      // Check if this record exists locally
      final existing = await db.query(
        table,
        where: 'sync_id = ?',
        whereArgs: [doc.id],
        limit: 1,
      );

      if (existing.isEmpty) {
        // New record from Firebase – insert locally (without the 'id' PK)
        final insertData = Map<String, dynamic>.from(data)..remove('id');
        await db.insert(table, insertData, conflictAlgorithm: 5 /* replace */);
      } else {
        final localRow = existing.first;
        final localUpdatedAt = (localRow['updated_at'] as int?) ?? 0;
        final remoteUpdatedAt = (data['updated_at'] as int?) ?? 0;
        final isDirty = (localRow['is_dirty'] as int?) == 1;

        bool dataDiffers = false;
        for (final key in data.keys) {
          if (key == 'updated_at' || key == 'is_dirty' || key == 'id') continue;
          if (data[key] != localRow[key]) {
            dataDiffers = true;
            break;
          }
        }

        // Update local if Firebase is newer, OR if forced, OR if Firebase data was
        // manually changed (differs) and local is not dirty.
        if (forcePull || remoteUpdatedAt > localUpdatedAt || (!isDirty && dataDiffers)) {
          final updateData = Map<String, dynamic>.from(data)..remove('id');
          await db.update(
            table,
            updateData,
            where: 'sync_id = ?',
            whereArgs: [doc.id],
          );
        }
      }
      count++;
    }

    return count;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _toFirestoreMap(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    // Firestore document ID = sync_id; keep it in the data too for queries
    data['updated_at'] ??= DateTime.now().millisecondsSinceEpoch;
    return data;
  }

  Future<int> _getLastSyncTimestamp() async {
    final raw = await DatabaseHelper.instance.getSetting('last_sync_timestamp');
    return int.tryParse(raw ?? '0') ?? 0;
  }

  Future<void> _setLastSyncTimestamp(int ts) async {
    await DatabaseHelper.instance.setSetting('last_sync_timestamp', ts.toString());
  }
}

/// Result object returned after a sync operation.
class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;
  final bool notAuthenticated;

  SyncResult({
    required this.pushed,
    required this.pulled,
    required this.errors,
  }) : notAuthenticated = false;

  SyncResult.notAuthenticated()
      : pushed = 0,
        pulled = 0,
        errors = const ['User not authenticated.'],
        notAuthenticated = true;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors && !notAuthenticated;

  @override
  String toString() =>
      'SyncResult(pushed: $pushed, pulled: $pulled, errors: $errors)';
}

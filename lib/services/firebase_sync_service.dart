import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

/// Manages bidirectional synchronisation between local SQLite and Firestore.
///
/// ## Strategy
///
/// ### First sync (lastSync == 0) — Richness-based
/// For every table compare local row-count vs Firestore doc-count:
///   | local | cloud | action                                   |
///   |-------|-------|------------------------------------------|
///   | 0     | > 0   | Pull all from cloud                      |
///   | N     | > N   | Pull all from cloud, then delta-push     |
///   | N     | <= N  | Push all local, delta-pull for any newer |
///   | equal | equal | Delta push+pull                          |
///
/// ### Subsequent syncs — Incremental Delta (Last-Write-Wins)
/// Push local rows with `updated_at > lastSync`. Pull cloud docs with
/// `updated_at > lastSync`. For conflicts, higher `updated_at` wins.
class FirebaseSyncService {
  static final FirebaseSyncService instance = FirebaseSyncService._();
  FirebaseSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Tables that participate in sync — order: parents before children
  static const List<String> _syncTables = [
    'settings',
    'users',
    'product_categories',  // must come before products
    'suppliers',
    'products',
    'customers',
    'purchase_orders',
    'purchase_order_items',
    'product_batches',     // must come after products
    'purchase_history',
    'daily_sales_sheets',
    'sales',
    'sale_items',
    'sales_returns',
    'sales_return_items',
    'expenses',
    'customer_payments',
    'supplier_payments',
  ];

  CollectionReference _col(String table) => _firestore.collection(table);

  bool _isSyncing = false;
  Timer? _debounceTimer;

  // ─── Auto-sync trigger ───────────────────────────────────────────────────────

  /// Call this after any local write to schedule a background push.
  /// Uses a 3-second debounce so rapid successive saves only trigger one sync.
  void triggerAutoSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      sync(); // silent background delta push — no forceInitial
    });
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Performs a full bidirectional sync.
  ///
  /// Set [forceInitial] = true to redo the smart initial-sync regardless of
  /// whether a previous sync has run (useful for "Reset Sync" in settings).
  ///
  /// Set [forceReset] = true (from the manual "Sync Now" button) to override
  /// a stuck [_isSyncing] flag and always attempt a fresh sync.
  Future<SyncResult> sync({bool forceInitial = false, bool forceReset = false}) async {
    if (_isSyncing && !forceReset) return SyncResult.busy();

    // If forceReset, cancel any debounce timer and clear the stuck flag
    if (forceReset) {
      _debounceTimer?.cancel();
      _isSyncing = false;
    }

    // Guard: user must be authenticated (check BEFORE setting _isSyncing)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SyncResult.notAuthenticated();

    _isSyncing = true;
    try {
      // Wrap entire sync in a 5-minute timeout to handle large initial pushes
      return await _runSyncBody(forceInitial).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          return SyncResult(
            pushed: 0,
            pulled: 0,
            errors: ['Sync timed out. Your connection may be slow or offline.'],
          );
        },
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// The actual sync logic, separated so it can be wrapped in a timeout.
  Future<SyncResult> _runSyncBody(bool forceInitial) async {
    try {
      int pushed = 0;
      int pulled = 0;
      final errors = <String>[];

      final db = await DatabaseHelper.instance.database;
      final lastSync = forceInitial ? 0 : await _getLastSyncTimestamp();

      for (final table in _syncTables) {
        try {
          if (lastSync == 0) {
            // ── First-time / forced: full bidirectional merge ──────────────────
            // Always push local AND pull cloud — _applySnapshot handles
            // conflict resolution (higher updated_at wins).

            // Step 1: Push all local rows to cloud
            final localRows =
                List<Map<String, dynamic>>.from(await db.query(table));
            if (localRows.isNotEmpty) {
              pushed += await _pushRows(db, table, localRows);
            }

            // Step 2: Pull all cloud rows and merge into local
            final snap = await _col(table).get().timeout(const Duration(seconds: 15));
            if (snap.docs.isNotEmpty) {
              pulled += await _applySnapshot(db, table, snap);
            }
          } else {
            // ── Subsequent syncs: incremental delta ────────────────────────────
            pushed += await _deltaPush(db, table, lastSync);
            pulled += await _deltaPull(db, table, lastSync);
          }
        } catch (e) {
          errors.add('$table: $e');
        }
      }

      await _setLastSyncTimestamp(DateTime.now().millisecondsSinceEpoch);

      // Write a lightweight summary to _sync_metadata (one doc, not per-table)
      try {
        await _firestore.collection('_sync_metadata').doc('last_sync').set({
          'timestamp': FieldValue.serverTimestamp(),
          'pushed': pushed,
          'pulled': pulled,
          'errorCount': errors.length,
          'errors': errors.take(5).toList(),
          'status': errors.isEmpty ? 'success' : 'partial',
        }, SetOptions(merge: true));
      } catch (_) {} // Don't fail the sync just because metadata write failed

      return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
    } catch (e) {
      return SyncResult(pushed: 0, pulled: 0, errors: ['Sync error: $e']);
    }
  }

  // ─── Incremental Push (local → Firebase) ────────────────────────────────────

  Future<int> _deltaPush(dynamic db, String table, int lastSync) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = List<Map<String, dynamic>>.from(await db.query(
        table,
        where: 'updated_at > ? OR sync_id IS NULL',
        whereArgs: [lastSync],
        orderBy: 'updated_at ASC', // oldest first so partial pushes make progress
      ));
    } catch (_) {
      rows = List<Map<String, dynamic>>.from(await db.query(table));
    }

    if (rows.isEmpty) return 0;
    return _pushRows(db, table, rows);
  }

  // ─── Incremental Pull (Firebase → local) ────────────────────────────────────

  Future<int> _deltaPull(dynamic db, String table, int lastSync) async {
    print('DEBUG: _deltaPull called for table: $table with lastSync: $lastSync');
    try {
      final QuerySnapshot snap = await _col(table)
          .where('updated_at', isGreaterThan: lastSync)
          .get()
          .timeout(const Duration(seconds: 15));
      print('DEBUG: _deltaPull query for $table returned ${snap.docs.length} docs.');
      if (snap.docs.isEmpty) return 0;
      return await _applySnapshot(db, table, snap);
    } catch (e, st) {
      print('DEBUG: Error in _deltaPull for $table: $e\n$st');
      rethrow;
    }
  }

  // ─── Core: push a list of local rows to Firestore ───────────────────────────

  Future<int> _pushRows(
    dynamic db,
    String table,
    List<Map<String, dynamic>> rawRows,
  ) async {
    if (rawRows.isEmpty) return 0;

    // SQLite returns read-only maps. Convert them to mutable maps immediately.
    final mutableRows = rawRows.map((e) => Map<String, dynamic>.from(e)).toList();

    // Collect rows that need a new sync_id and assign them in one local pass
    final rowsNeedingId = <Map<String, dynamic>>[];
    for (final row in mutableRows) {
      if ((row['sync_id'] as String?) == null ||
          (row['sync_id'] as String).isEmpty) {
        rowsNeedingId.add(row);
      }
    }

    // Batch-update sync_ids in SQLite if needed
    if (rowsNeedingId.isNotEmpty) {
      final batch = db.batch();
      for (final row in rowsNeedingId) {
        final syncId = _uuid.v4();
        row['sync_id'] = syncId;
        row['updated_at'] =
            row['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
        final pkCol = (table == 'settings') ? 'key' : 'id';
        try {
          batch.update(
            table,
            {'sync_id': syncId, 'updated_at': row['updated_at']},
            where: '$pkCol = ?',
            whereArgs: [row[pkCol]],
          );
        } catch (_) {}
      }
      await batch.commit(noResult: true);
    }

    // Push to Firestore in 200-op batches (well within Firestore's 500-op limit).
    // Smaller batches = faster per-commit round trips = less risk of overall timeout.
    var fbBatch = _firestore.batch();
    int total = 0;
    int batchSize = 0;

    for (final row in mutableRows) {
      final syncId = (row['sync_id'] as String?) ?? _uuid.v4();
      row['updated_at'] ??= DateTime.now().millisecondsSinceEpoch;
      fbBatch.set(_col(table).doc(syncId), row, SetOptions(merge: true));
      total++;
      batchSize++;

      if (batchSize == 200) {
        await fbBatch.commit().timeout(const Duration(seconds: 15));
        fbBatch = _firestore.batch();
        batchSize = 0;
      }
    }

    if (batchSize > 0) {
      await fbBatch.commit().timeout(const Duration(seconds: 15));
    }
    return total;
  }

  // ─── Core: apply a Firestore snapshot to the local DB ───────────────────────
  //
  // Uses a single bulk query to load all existing sync_ids into memory,
  // avoiding N individual queries for N documents.

  Future<int> _applySnapshot(
    dynamic db,
    String table,
    QuerySnapshot snapshot,
  ) async {
    print('DEBUG: _applySnapshot called for table: $table with ${snapshot.docs.length} docs.');
    if (snapshot.docs.isEmpty) return 0;

    // Read actual column names from local schema to safely filter Firestore data
    final List<Map<String, dynamic>> pragmaRows =
        List<Map<String, dynamic>>.from(await db.rawQuery('PRAGMA table_info($table)'));
    final localColumns = pragmaRows.map((r) => r['name'] as String).toSet();

    // Load all existing sync_ids for this table into a map: sync_id -> updated_at
    final List<Map<String, dynamic>> existingRows =
        List<Map<String, dynamic>>.from(
      await db.query(table, columns: ['sync_id', 'updated_at']),
    );
    final existingMap = <String, int>{};
    for (final row in existingRows) {
      final sid = row['sync_id'] as String?;
      if (sid != null) {
        existingMap[sid] = (row['updated_at'] as int?) ?? 0;
      }
    }

    int count = 0;
    final insertBatch = db.batch();
    final updateBatch = db.batch();

    for (final doc in snapshot.docs) {
      final rawData =
          Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      rawData['sync_id'] = doc.id;
      if (localColumns.contains('is_deleted')) {
        rawData['is_deleted'] = (rawData['is_deleted'] as int?) ?? 0;
      }

      // Strip any fields that don't exist locally to avoid "no such column" errors
      final data = Map<String, dynamic>.fromEntries(
        rawData.entries.where((e) => localColumns.contains(e.key)),
      );

      try {
        final localTs = existingMap[doc.id];
        final int remoteTs = (data['updated_at'] as int?) ?? 0;
        print('DEBUG: table $table, doc ${doc.id} - localTs: $localTs, remoteTs: $remoteTs');

        if (localTs == null) {
          // New record from cloud — preserve the integer 'id' so foreign keys
          // in child tables (e.g. sale_id, product_id) remain valid.
          insertBatch.insert(table, Map<String, dynamic>.from(data),
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        } else if (remoteTs >= localTs) {
          // Remote is newer — update local (don't overwrite local integer id)
          final updateData = Map<String, dynamic>.from(data)..remove('id');
          updateBatch.update(
            table,
            updateData,
            where: 'sync_id = ?',
            whereArgs: [doc.id],
          );
          count++;
        } else {
          print('DEBUG: Skipping pull for $table doc ${doc.id} because localTs ($localTs) > remoteTs ($remoteTs)');
        }
      } catch (e, st) {
        print('DEBUG: Error preparing batch for $table doc ${doc.id}: $e\n$st');
      }
    }

    try {
      await insertBatch.commit(noResult: true);
      print('DEBUG: Successfully committed insertBatch for $table');
    } catch (e, st) {
      print('DEBUG: Error committing insertBatch for $table: $e\n$st');
    }

    try {
      await updateBatch.commit(noResult: true);
      print('DEBUG: Successfully committed updateBatch for $table');
    } catch (e, st) {
      print('DEBUG: Error committing updateBatch for $table: $e\n$st');
    }
    return count;
  }

  // ─── Timestamp helpers ───────────────────────────────────────────────────────

  Future<int> _getLastSyncTimestamp() async {
    final raw = await DatabaseHelper.instance.getSetting('last_sync_timestamp');
    return int.tryParse(raw ?? '0') ?? 0;
  }

  Future<void> _setLastSyncTimestamp(int ts) async {
    await DatabaseHelper.instance
        .setSetting('last_sync_timestamp', ts.toString());
  }

  /// Wipes all local and cloud data completely
  Future<void> wipeAllData() async {
    // 1. Wipe Firebase data if authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        for (final table in _syncTables) {
          final snapshot = await _col(table).get();
          final docs = snapshot.docs;
          for (int i = 0; i < docs.length; i += 400) {
            final batch = _firestore.batch();
            final end = (i + 400 < docs.length) ? i + 400 : docs.length;
            for (int j = i; j < end; j++) {
              batch.delete(docs[j].reference);
            }
            await batch.commit();
          }
        }
      } catch (e) {
        // Continue even if network fails, to ensure local wipe happens
      }
    }

    // 2. Wipe Local DB
    await DatabaseHelper.instance.wipeDatabase();
  }
}

// ─── Public result object ─────────────────────────────────────────────────────

class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;
  final bool notAuthenticated;
  final bool offline;
  final bool busy;

  SyncResult({
    required this.pushed,
    required this.pulled,
    required this.errors,
  })  : notAuthenticated = false,
        offline = false,
        busy = false;

  SyncResult.notAuthenticated()
      : pushed = 0,
        pulled = 0,
        errors = const ['User not authenticated.'],
        notAuthenticated = true,
        offline = false,
        busy = false;

  SyncResult.offline()
      : pushed = 0,
        pulled = 0,
        errors = const ['Device is offline.'],
        notAuthenticated = false,
        offline = true,
        busy = false;

  SyncResult.busy()
      : pushed = 0,
        pulled = 0,
        errors = const [],
        notAuthenticated = false,
        offline = false,
        busy = true;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors && !notAuthenticated && !offline && !busy;

  @override
  String toString() =>
      'SyncResult(pushed: $pushed, pulled: $pulled, errors: $errors)';
}


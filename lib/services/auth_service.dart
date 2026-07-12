import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  String? currentUserId;
  String? currentUserEmail;
  String? currentUserName;
  String? currentUserRole; // 'admin' or 'cashier'
  bool currentUserIsActive = true;

  bool get isAdmin => currentUserRole == 'admin';
  bool get isCashier => currentUserRole == 'cashier';

  /// Loads user metadata from the local SQLite `users` table
  /// based on the given Firebase Auth User.
  Future<void> loadUserMetadata(User firebaseUser) async {
    currentUserId = firebaseUser.uid;
    currentUserEmail = firebaseUser.email;
    
    final db = await DatabaseHelper.instance.database;
    // Check if user exists in local SQLite
    // Also we need to check if table has is_deleted. I should check database schema. 
    // Wait, the table I created did NOT have `is_deleted`. I must use basic query.
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [firebaseUser.uid],
      limit: 1,
    );

    if (results.isNotEmpty) {
      final userRow = results.first;
      currentUserName = userRow['full_name'];
      currentUserRole = userRow['role'];
      currentUserIsActive = (userRow['is_active'] as int) == 1;
    } else {
      // If the user isn't in SQLite, it might be the initial Admin logging in.
      final List<Map<String, dynamic>> allUsers = await db.query('users');
      if (allUsers.isEmpty) {
        // No users at all -> First time Admin setup. 
        await db.insert('users', {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'full_name': 'Admin',
          'role': 'admin',
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'sync_id': firebaseUser.uid,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        currentUserName = 'Admin';
        currentUserRole = 'admin';
        currentUserIsActive = true;
      } else {
        // Unknown user.
        currentUserName = 'Unknown';
        currentUserRole = 'cashier';
        currentUserIsActive = false;
      }
    }
  }

  void clear() {
    currentUserId = null;
    currentUserEmail = null;
    currentUserName = null;
    currentUserRole = null;
    currentUserIsActive = true;
  }
}

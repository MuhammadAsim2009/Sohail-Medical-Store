import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharmacy/services/firebase_sync_service.dart';
import 'package:pharmacy/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  print('Starting sync test...');
  try {
    final result = await FirebaseSyncService.instance.sync(forceReset: true);
    print('Sync finished. Busy: ${result.busy}, Offline: ${result.offline}, Authenticated: ${!result.notAuthenticated}');
    print('Pushed: ${result.pushed}, Pulled: ${result.pulled}');
    print('Errors: ${result.errors}');
  } catch (e, stack) {
    print('Sync crashed: $e');
    print(stack);
  }
}

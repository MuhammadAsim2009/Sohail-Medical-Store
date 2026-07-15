import 'package:flutter/material.dart';
import 'package:pharmacy/services/firebase_sync_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharmacy/firebase_options.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pharmacy/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final result = await FirebaseSyncService.instance.sync(forceInitial: true);
  
  print('--- SYNC RESULT ---');
  print('Offline: $result.offline');
  print('Auth error: $result.notAuthenticated');
  print('Pushed: $result.pushed');
  print('Pulled: $result.pulled');
  print('Errors:');
  for (var err in result.errors) {
    print(err);
  }
  print('-------------------');
  exit(0);
}

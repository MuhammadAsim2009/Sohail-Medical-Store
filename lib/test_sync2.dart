import 'package:pharmacy/services/firebase_sync_service.dart';
import 'package:pharmacy/services/database_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('Starting sync...');
  final result = await FirebaseSyncService.instance.sync(forceInitial: false, forceReset: true);
  print('Sync finished! Pushed: ${result.pushed}, Pulled: ${result.pulled}');
  if (result.errors.isNotEmpty) {
    print('Errors:');
    for (var e in result.errors) {
      print(e);
    }
  }
}

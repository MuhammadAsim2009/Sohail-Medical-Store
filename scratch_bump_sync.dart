import 'package:pharmacy/services/database_helper.dart';
import 'package:pharmacy/services/firebase_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await DatabaseHelper.instance.database;
  
  final now = DateTime.now().millisecondsSinceEpoch;
  
  final cCount = await db.rawUpdate('UPDATE customers SET updated_at = ?', [now]);
  print('Updated \$cCount customers');
  
  final dCount = await db.rawUpdate('UPDATE daily_sales_sheets SET updated_at = ?', [now]);
  print('Updated \$dCount DSS');
  
  final sCount = await db.rawUpdate('UPDATE supplier_payments SET updated_at = ?', [now]);
  print('Updated \$sCount supplier payments');

  final pCount = await db.rawUpdate('UPDATE customer_payments SET updated_at = ?', [now]);
  print('Updated \$pCount customer payments');

  print('Done.');
}

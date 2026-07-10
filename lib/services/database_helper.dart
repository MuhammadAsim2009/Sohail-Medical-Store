import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/daily_sales_sheet.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/sales_return.dart';
import '../models/customer_payment.dart';
import '../models/supplier_payment.dart';
import 'firebase_sync_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const _uuid = Uuid();

  /// Stamps [map] with a new [sync_id] (if absent) and the current
  /// [updated_at] Unix timestamp (ms). Returns the mutated map.
  static Map<String, dynamic> _stamp(Map<String, dynamic> map, {bool isUpdate = false}) {
    if (!isUpdate) { map['sync_id'] ??= _uuid.v4(); }
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return map;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pharmacy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 20,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await _createDB(db, newVersion);
      return;
    }
    if (oldVersion < 3) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS purchase_orders (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  po_number   TEXT UNIQUE NOT NULL,
  supplier    TEXT NOT NULL,
  order_date  TEXT NOT NULL,
  status      TEXT NOT NULL,
  notes       TEXT,
  tax_rate    REAL NOT NULL DEFAULT 0.0,
  tax_amount  REAL NOT NULL DEFAULT 0.0,
  paid_amount REAL NOT NULL DEFAULT 0.0,
  discount    REAL NOT NULL DEFAULT 0.0
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id       INTEGER NOT NULL,
  product_id     INTEGER,
  product_name   TEXT NOT NULL,
  unit_purchased TEXT NOT NULL,
  quantity       REAL NOT NULL,
  purchase_price REAL NOT NULL,
  selling_price  REAL NOT NULL DEFAULT 0.0,
  discount       REAL NOT NULL DEFAULT 0.0,
  expiry_date    TEXT,
  FOREIGN KEY (order_id) REFERENCES purchase_orders (id) ON DELETE CASCADE
)""");
    }
    if (oldVersion < 4) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS suppliers (
  id                 TEXT PRIMARY KEY,
  companyName        TEXT NOT NULL,
  contactPerson      TEXT NOT NULL,
  phone              TEXT NOT NULL,
  email              TEXT NOT NULL,
  address            TEXT NOT NULL,
  categoriesSupplied TEXT NOT NULL,
  lastOrderDate      TEXT NOT NULL,
  pendingAmount      REAL NOT NULL DEFAULT 0.0,
  advanceAmount      REAL NOT NULL DEFAULT 0.0
)""");
    }
    if (oldVersion < 5) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS customers (
  id                 TEXT PRIMARY KEY,
  name               TEXT NOT NULL,
  phone              TEXT NOT NULL,
  email              TEXT,
  address            TEXT,
  totalPurchases     REAL NOT NULL DEFAULT 0.0,
  pendingAmount      REAL NOT NULL DEFAULT 0.0,
  advanceAmount      REAL NOT NULL DEFAULT 0.0,
  lastVisit          TEXT NOT NULL
)""");
    }
    if (oldVersion < 6) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS daily_sales_sheets (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  date            TEXT NOT NULL,
  opening_balance REAL NOT NULL,
  expected_cash   REAL NOT NULL,
  actual_cash     REAL NOT NULL,
  status          TEXT NOT NULL
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS sales (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  dss_id          INTEGER NOT NULL,
  invoice_number  TEXT NOT NULL,
  date            TEXT NOT NULL,
  customer_id     TEXT,
  customer_name   TEXT,
  total           REAL NOT NULL,
  received        REAL NOT NULL,
  balance         REAL NOT NULL,
  payment_method  TEXT NOT NULL,
  status          TEXT NOT NULL,
    tax_rate        REAL NOT NULL DEFAULT 0.0,
    tax_amount      REAL NOT NULL DEFAULT 0.0,
    discount        REAL NOT NULL DEFAULT 0.0,
  FOREIGN KEY (dss_id) REFERENCES daily_sales_sheets (id) ON DELETE RESTRICT
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS sale_items (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id         INTEGER NOT NULL,
  product_id      INTEGER NOT NULL,
  product_name    TEXT NOT NULL,
  quantity        INTEGER NOT NULL,
  price           REAL NOT NULL,
  total           REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
)""");
    }
    if (oldVersion < 7) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS suppliers_new (
  id                 TEXT PRIMARY KEY,
  companyName        TEXT NOT NULL,
  contactPerson      TEXT NOT NULL,
  phone              TEXT NOT NULL,
  email              TEXT NOT NULL,
  address            TEXT NOT NULL,
  categoriesSupplied TEXT NOT NULL,
  lastOrderDate      TEXT NOT NULL,
  pendingAmount      REAL NOT NULL DEFAULT 0.0,
  advanceAmount      REAL NOT NULL DEFAULT 0.0
)""");
    }
    if (oldVersion < 8) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS expenses (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  date        TEXT NOT NULL,
  category    TEXT NOT NULL,
  title       TEXT NOT NULL,
  amount      REAL NOT NULL,
  notes       TEXT
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS customer_payments (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id TEXT NOT NULL,
  date        TEXT NOT NULL,
  amount      REAL NOT NULL,
  reference   TEXT NOT NULL,
  invoice_number TEXT,
  notes       TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS supplier_payments (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  supplier_id TEXT NOT NULL,
  date        TEXT NOT NULL,
  amount      REAL NOT NULL,
  reference   TEXT NOT NULL,
  invoice_number TEXT,
  notes       TEXT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
)""");
    }
    if (oldVersion < 14) {
      // version 14 updates (empty or logic from before)
    }
    if (oldVersion < 15) {
      // Add missing columns to settings table
      try { await db.execute("ALTER TABLE settings ADD COLUMN sync_id TEXT"); } catch(_) {}
      try { await db.execute("ALTER TABLE settings ADD COLUMN updated_at INTEGER DEFAULT 0"); } catch(_) {}
      try { await db.execute("ALTER TABLE settings ADD COLUMN is_dirty INTEGER DEFAULT 0"); } catch(_) {}
      try { await db.execute("ALTER TABLE settings ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch(_) {}
    }
    if (oldVersion < 18) {
      // Add missing tax_amount to purchase_orders for legacy DBs
      try { await db.execute("ALTER TABLE purchase_orders ADD COLUMN tax_amount REAL NOT NULL DEFAULT 0.0"); } catch(_) {}
    }
    if (oldVersion < 19) {
      // Add missing tax columns to sales for legacy DBs
      try { await db.execute("ALTER TABLE sales ADD COLUMN tax_rate REAL NOT NULL DEFAULT 0.0"); } catch(_) {}
      try { await db.execute("ALTER TABLE sales ADD COLUMN tax_amount REAL NOT NULL DEFAULT 0.0"); } catch(_) {}
    }
    if (oldVersion < 20) {
      try { await db.execute("ALTER TABLE sales ADD COLUMN discount REAL NOT NULL DEFAULT 0.0"); } catch(_) {}
    }
    if (oldVersion < 21) {
      try { await db.execute("ALTER TABLE purchase_orders ADD COLUMN discount REAL NOT NULL DEFAULT 0.0"); } catch(_) {}
    }
  }

  // ---------------------------------------------------------------------------
  Future _createDB(Database db, int version) async {
    await db.execute("""
CREATE TABLE IF NOT EXISTS products (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id    TEXT UNIQUE,
  updated_at INTEGER,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  sku        TEXT UNIQUE NOT NULL,
  name       TEXT NOT NULL,
  category   TEXT NOT NULL,
  packaging  TEXT NOT NULL,
  cost_price REAL NOT NULL,
  sell_price REAL NOT NULL,
  stock      REAL NOT NULL,
  threshold  REAL NOT NULL
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS purchase_history (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id        TEXT UNIQUE,
  updated_at     INTEGER,
  is_deleted     INTEGER NOT NULL DEFAULT 0,
  product_id     INTEGER NOT NULL,
  purchase_date  TEXT NOT NULL,
  unit_purchased TEXT NOT NULL,
  quantity       REAL NOT NULL,
  cost_price     REAL NOT NULL,
  total_cost     REAL NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS purchase_orders (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id     TEXT UNIQUE,
  updated_at  INTEGER,
  is_deleted  INTEGER NOT NULL DEFAULT 0,
  po_number   TEXT UNIQUE NOT NULL,
  supplier    TEXT NOT NULL,
  order_date  TEXT NOT NULL,
  status      TEXT NOT NULL,
  notes       TEXT,
  tax_rate    REAL NOT NULL DEFAULT 0.0,
  paid_amount REAL NOT NULL DEFAULT 0.0,
  discount    REAL NOT NULL DEFAULT 0.0
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id        TEXT UNIQUE,
  updated_at     INTEGER,
  is_deleted     INTEGER NOT NULL DEFAULT 0,
  order_id       INTEGER NOT NULL,
  product_id     INTEGER,
  product_name   TEXT NOT NULL,
  unit_purchased TEXT NOT NULL,
  quantity       REAL NOT NULL,
  purchase_price REAL NOT NULL,
  selling_price  REAL NOT NULL DEFAULT 0.0,
  discount       REAL NOT NULL DEFAULT 0.0,
  expiry_date    TEXT,
  FOREIGN KEY (order_id) REFERENCES purchase_orders (id) ON DELETE CASCADE
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS suppliers (
  id                 TEXT PRIMARY KEY,
  sync_id            TEXT UNIQUE,
  updated_at         INTEGER,
  is_deleted         INTEGER NOT NULL DEFAULT 0,
  companyName        TEXT NOT NULL,
  contactPerson      TEXT NOT NULL,
  phone              TEXT NOT NULL,
  email              TEXT NOT NULL,
  address            TEXT NOT NULL,
  categoriesSupplied TEXT NOT NULL,
  lastOrderDate      TEXT NOT NULL,
  pendingAmount      REAL NOT NULL DEFAULT 0.0,
  advanceAmount      REAL NOT NULL DEFAULT 0.0
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS customers (
  id                 TEXT PRIMARY KEY,
  sync_id            TEXT UNIQUE,
  updated_at         INTEGER,
  is_deleted         INTEGER NOT NULL DEFAULT 0,
  name               TEXT NOT NULL,
  phone              TEXT NOT NULL,
  email              TEXT,
  address            TEXT,
  totalPurchases     REAL NOT NULL DEFAULT 0.0,
  pendingAmount      REAL NOT NULL DEFAULT 0.0,
  advanceAmount      REAL NOT NULL DEFAULT 0.0,
  lastVisit          TEXT NOT NULL
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS daily_sales_sheets (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id         TEXT UNIQUE,
  updated_at      INTEGER,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  date            TEXT NOT NULL,
  opening_balance REAL NOT NULL,
  expected_cash   REAL NOT NULL,
  actual_cash     REAL NOT NULL,
  status          TEXT NOT NULL
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS sales (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id         TEXT UNIQUE,
  updated_at      INTEGER,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  dss_id          INTEGER NOT NULL,
  invoice_number  TEXT NOT NULL,
  date            TEXT NOT NULL,
  customer_id     TEXT,
  customer_name   TEXT,
  total           REAL NOT NULL,
  received        REAL NOT NULL,
  balance         REAL NOT NULL,
  payment_method  TEXT NOT NULL,
  status          TEXT NOT NULL,
  tax_rate        REAL NOT NULL DEFAULT 0.0,
  tax_amount      REAL NOT NULL DEFAULT 0.0,
  FOREIGN KEY (dss_id) REFERENCES daily_sales_sheets (id) ON DELETE RESTRICT
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS sale_items (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id         TEXT UNIQUE,
  updated_at      INTEGER,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  sale_id         INTEGER NOT NULL,
  product_id      INTEGER NOT NULL,
  product_name    TEXT NOT NULL,
  quantity        INTEGER NOT NULL,
  price           REAL NOT NULL,
  total           REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS sales_returns (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id         TEXT UNIQUE,
  updated_at      INTEGER,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  dss_id          INTEGER NOT NULL,
  date            TEXT NOT NULL,
  invoice_number  TEXT NOT NULL,
  return_number   TEXT,
  customer_name   TEXT,
  mode            TEXT NOT NULL,
  reason          TEXT NOT NULL,
  total_refund    REAL NOT NULL,
  cash_refunded   REAL NOT NULL,
  credit_issued   REAL NOT NULL,
  status          TEXT NOT NULL
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS sales_return_items (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id           TEXT UNIQUE,
  updated_at        INTEGER,
  is_deleted        INTEGER NOT NULL DEFAULT 0,
  sales_return_id   INTEGER NOT NULL,
  product_id        INTEGER NOT NULL,
  product_name      TEXT NOT NULL,
  unit_name         TEXT NOT NULL DEFAULT 'Base Unit',
  quantity_returned REAL NOT NULL,
  price             REAL NOT NULL,
  total             REAL NOT NULL,
  FOREIGN KEY (sales_return_id) REFERENCES sales_returns (id) ON DELETE CASCADE
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS expenses (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id     TEXT UNIQUE,
  updated_at  INTEGER,
  is_deleted  INTEGER NOT NULL DEFAULT 0,
  date        TEXT NOT NULL,
  category    TEXT NOT NULL,
  title       TEXT NOT NULL,
  amount      REAL NOT NULL,
  notes       TEXT
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS customer_payments (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id     TEXT UNIQUE,
  updated_at  INTEGER,
  is_deleted  INTEGER NOT NULL DEFAULT 0,
  customer_id TEXT NOT NULL,
  date        TEXT NOT NULL,
  amount      REAL NOT NULL,
  reference   TEXT NOT NULL,
  invoice_number TEXT,
  notes       TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
)""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS supplier_payments (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id     TEXT UNIQUE,
  updated_at  INTEGER,
  is_deleted  INTEGER NOT NULL DEFAULT 0,
  supplier_id TEXT NOT NULL,
  date        TEXT NOT NULL,
  amount      REAL NOT NULL,
  reference   TEXT NOT NULL,
  invoice_number TEXT,
  notes       TEXT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
)""");

    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  // ---------------------------------------------------------------------------

  // SETTINGS
  // ---------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    // Check if updated_at column exists (added in migration v15)
    final cols = await db.rawQuery('PRAGMA table_info(settings)');
    final colNames = cols.map((c) => c['name'] as String).toSet();
    final hasUpdatedAt = colNames.contains('updated_at');

    final data = <String, dynamic>{
      'value': value,
      if (hasUpdatedAt) 'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    final existing = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (existing.isNotEmpty) {
      await db.update('settings', data, where: 'key = ?', whereArgs: [key]);
    } else {
      data['key'] = key;
      await db.insert('settings', data);
    }
      FirebaseSyncService.instance.triggerAutoSync();
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await instance.database;
    final maps = await db.query('settings');
    return {for (var map in maps) map['key'] as String: map['value'] as String};
  }

  // -- PRODUCTS ----------------------------------------------------------------

  Future<Product> insertProduct(Product product) async {
    final db = await instance.database;
    final map = _stamp(product.toMap());
    final id = await db.insert('products', map);
    product.id = id;
        FirebaseSyncService.instance.triggerAutoSync();
return product;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await instance.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    final map = _stamp(product.toMap());
        FirebaseSyncService.instance.triggerAutoSync();
return db.update('products', _stamp(map, isUpdate: true),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> purchaseStock(
    Product product,
    String unitPurchased,
    double qtyPurchased,
    double costPerUnit,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final multiplier = product.getMultiplier(unitPurchased);
      final newStock = product.stock + qtyPurchased * multiplier;
      await txn.update('products', {'stock': newStock, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?', whereArgs: [product.id]);
      await txn.insert('purchase_history', _stamp({
        'product_id': product.id,
        'purchase_date': DateTime.now().toIso8601String(),
        'unit_purchased': unitPurchased,
        'quantity': qtyPurchased,
        'cost_price': costPerUnit,
        'total_cost': qtyPurchased * costPerUnit,
      }));
    });
      FirebaseSyncService.instance.triggerAutoSync();
  }

  // -- PURCHASE ORDERS ---------------------------------------------------------

  Future<String> _nextPoNumber(Transaction txn) async {
    final rows =
        await txn.rawQuery('SELECT COUNT(*) as cnt FROM purchase_orders');
    final count = (rows.first['cnt'] as int?) ?? 0;
    return 'PO-${1001 + count}';
  }

  Future<PurchaseOrder> insertPurchaseOrder(PurchaseOrder order) async {
    final db = await instance.database;
    late PurchaseOrder saved;
    await db.transaction((txn) async {
      final poNumber = await _nextPoNumber(txn);
      final orderId = await txn.insert('purchase_orders', _stamp({
        'po_number': poNumber,
        'supplier': order.supplier,
        'order_date': order.orderDate.toIso8601String(),
        'status': order.status,
        'notes': order.notes,
        'tax_rate': order.taxRate,
        'tax_amount': order.taxAmount,
        'paid_amount': order.paidAmount,
        'discount': order.discount,
      }));
      final savedItems = <PurchaseOrderItem>[];
      for (final item in order.items) {
        final itemId = await txn.insert('purchase_order_items', _stamp({
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_purchased': item.unitPurchased,
          'quantity': item.quantity,
          'purchase_price': item.purchasePrice,
          'selling_price': item.sellingPrice,
          'discount': item.discount,
          'expiry_date': item.expiryDate?.toIso8601String(),
        }));
        savedItems.add(item.copyWith(id: itemId));
      }
      saved = order.copyWith(id: orderId, poNumber: poNumber, items: savedItems);
    });
        FirebaseSyncService.instance.triggerAutoSync();
return saved;
  }

  Future<List<PurchaseOrder>> getAllPurchaseOrders() async {
    final db = await instance.database;
    final orderRows = await db.query('purchase_orders', orderBy: 'id DESC');
    final orders = <PurchaseOrder>[];
    for (final row in orderRows) {
      final orderId = row['id'] as int;
      final itemRows = await db.query('purchase_order_items',
          where: 'order_id = ?', whereArgs: [orderId]);
      orders.add(PurchaseOrder.fromMap(
          row, itemRows.map(PurchaseOrderItem.fromMap).toList()));
    }
    return orders;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await instance.database;
    await db.update('purchase_orders', {'status': status, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [orderId]);
      FirebaseSyncService.instance.triggerAutoSync();
  }

  Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'purchase_orders',
        _stamp({
          'supplier': order.supplier,
          'notes': order.notes,
          'tax_rate': order.taxRate,
          'tax_amount': order.taxAmount,
          'paid_amount': order.paidAmount,
          'discount': order.discount,
          'status': order.status,
        }),
        where: 'id = ?',
        whereArgs: [order.id],
      );
      await txn.delete('purchase_order_items',
          where: 'order_id = ?', whereArgs: [order.id]);
      for (final item in order.items) {
        await txn.insert('purchase_order_items', _stamp({
          'order_id': order.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_purchased': item.unitPurchased,
          'quantity': item.quantity,
          'purchase_price': item.purchasePrice,
          'selling_price': item.sellingPrice,
          'discount': item.discount,
          'expiry_date': item.expiryDate?.toIso8601String(),
        }));
      }
    });
      FirebaseSyncService.instance.triggerAutoSync();
  }

  /// Mark as Received and atomically credit inventory stock.
  Future<void> receivePurchaseOrder(PurchaseOrder order) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update('purchase_orders', {'status': 'Received', 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?', whereArgs: [order.id]);
      for (final item in order.items) {
        if (item.productId == null) continue;
        final rows = await txn.query('products',
            where: 'id = ?', whereArgs: [item.productId]);
        if (rows.isEmpty) continue;
        final product = Product.fromMap(rows.first);
        final multiplier = product.getMultiplier(item.unitPurchased);
        final newStock = product.stock + item.quantity * multiplier;

        final Map<String, dynamic> updateMap = {'stock': newStock};
        if (item.purchasePrice > 0) updateMap['cost_price'] = item.purchasePrice;
        if (item.sellingPrice > 0)  updateMap['sell_price'] = item.sellingPrice;

        updateMap['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await txn.update('products', updateMap,
            where: 'id = ?', whereArgs: [item.productId]);
        await txn.insert('purchase_history', _stamp({
          'product_id': item.productId,
          'purchase_date': DateTime.now().toIso8601String(),
          'unit_purchased': item.unitPurchased,
          'quantity': item.quantity,
          'cost_price': item.purchasePrice,
          'total_cost': item.quantity * item.purchasePrice,
        }));
      }

      final supplierRows = await txn.query(
        'suppliers',
        where: 'companyName = ?',
        whereArgs: [order.supplier],
        limit: 1,
      );
      if (supplierRows.isNotEmpty) {
        final supplier = supplierRows.first;
        final supplierId = supplier['id']?.toString();
        if (supplierId != null && supplierId.isNotEmpty) {
          final orderTotal = order.totalAmount;
          final paidAmount = order.paidAmount;
          final dueAmount = (orderTotal - paidAmount).clamp(0.0, double.infinity);
          final advanceAmount = (paidAmount - orderTotal).clamp(0.0, double.infinity);
          final existingPending = (supplier['pendingAmount'] as num?)?.toDouble() ?? 0.0;
          final existingAdvance = (supplier['advanceAmount'] as num?)?.toDouble() ?? 0.0;
          final updates = <String, Object?>{
            'lastOrderDate': DateTime.now().toIso8601String(),
            'pendingAmount': existingPending + dueAmount,
          };
          if (advanceAmount > 0) {
            updates['advanceAmount'] = existingAdvance + advanceAmount;
          }
          updates['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          await txn.update('suppliers', updates, where: 'id = ?', whereArgs: [supplierId]);
        }
      }
    });
      FirebaseSyncService.instance.triggerAutoSync();
  }

  // -- SUPPLIERS ---------------------------------------------------------------

  Future<void> insertSupplier(Supplier supplier) async {
    final db = await instance.database;
    await db.insert(
      'suppliers',
      _stamp(supplier.toMap()),  // isUpdate defaults to false → assigns new sync_id
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
      FirebaseSyncService.instance.triggerAutoSync();
  }

  Future<List<Supplier>> getSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return db.update(
      'suppliers',
      _stamp(supplier.toMap(), isUpdate: true),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(String id) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> nextSaleInvoiceNumber() async {
    final db = await instance.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM sales');
    final count = (rows.first['cnt'] as int?) ?? 0;
    return 'INV-${(count + 1).toString().padLeft(3, '0')}';
  }

  Future<String> nextReturnNumber() async {
    final db = await instance.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM sales_returns');
    final count = (rows.first['cnt'] as int?) ?? 0;
    return 'SR-${(count + 1).toString().padLeft(3, '0')}';
  }

  // -- CUSTOMERS ---------------------------------------------------------------

  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return await db.insert('customers', _stamp(customer.toMap()));  // assigns new sync_id
  }

  Future<List<Customer>> getCustomers() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return await db.update('customers', _stamp(customer.toMap(), isUpdate: true),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(String id) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // -- DAILY SALES SHEETS (DSS) ------------------------------------------------

  Future<DailySalesSheet?> getCurrentOpenDSS() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_sales_sheets',
      where: 'status = ?',
      whereArgs: ['OPEN'],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DailySalesSheet.fromMap(maps.first);
    }
    return null;
  }

  Future<int> openDSS(double openingBalance) async {
    final db = await instance.database;
    final current = await getCurrentOpenDSS();
    if (current != null) {
      throw Exception('A Daily Sales Sheet is already open. Close it first.');
    }
    final dss = DailySalesSheet(
      date: DateTime.now().toIso8601String(),
      openingBalance: openingBalance,
      expectedCash: openingBalance,
      actualCash: 0.0,
      status: 'OPEN',
    );
        FirebaseSyncService.instance.triggerAutoSync();
return await db.insert('daily_sales_sheets', _stamp(dss.toMap()));
  }

  Future<int> closeDSS(int dssId, double actualCash) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(received) as total_cash FROM sales WHERE dss_id = ? AND payment_method = ?',
      [dssId, 'Cash']
    );
    double totalCashSales = 0.0;
    if (result.isNotEmpty && result.first['total_cash'] != null) {
      totalCashSales = result.first['total_cash'] as double;
    }
    final dssMaps = await db.query('daily_sales_sheets', where: 'id = ?', whereArgs: [dssId]);
    if (dssMaps.isEmpty) throw Exception('DSS not found');
    final dss = DailySalesSheet.fromMap(dssMaps.first);
    final expectedCash = dss.openingBalance + totalCashSales;
        FirebaseSyncService.instance.triggerAutoSync();
return await db.update(
        'daily_sales_sheets',
        _stamp({
          'status': 'CLOSED',
          'expected_cash': expectedCash,
          'actual_cash': actualCash,
        }, isUpdate: true),
      where: 'id = ?',
      whereArgs: [dssId],
    );
  }

  // -- SALES -------------------------------------------------------------------

  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await instance.database;
    int saleId = 0;
    await db.transaction((txn) async {
      final saleMap = _stamp(sale.toMap());
      saleMap.remove('id');
      saleId = await txn.insert('sales', saleMap);
      for (var item in items) {
        final itemMap = _stamp(item.toMap());
        itemMap.remove('id');
        itemMap['sale_id'] = saleId;
        await txn.insert('sale_items', itemMap);
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
            [item.quantity, DateTime.now().millisecondsSinceEpoch, item.productId]
        );
      }
      if (sale.customerId != null && sale.customerId!.isNotEmpty) {
        final dueAmount = (sale.total - sale.received).clamp(0.0, double.infinity);
        final advanceAmount = (sale.received - sale.total).clamp(0.0, double.infinity);
        await txn.rawUpdate(
          'UPDATE customers SET pendingAmount = pendingAmount + ?, advanceAmount = advanceAmount + ?, totalPurchases = totalPurchases + ?, lastVisit = ? WHERE id = ?',
          [dueAmount, advanceAmount, sale.total, sale.date, sale.customerId]
        );
      }
      if (sale.paymentMethod == 'Cash') {
        await txn.rawUpdate(
          'UPDATE daily_sales_sheets SET expected_cash = expected_cash + ? WHERE id = ?',
          [sale.received, sale.dssId]
        );
      }
    });
        FirebaseSyncService.instance.triggerAutoSync();
return saleId;
  }

  Future<int> insertCustomerPayment(CustomerPayment payment) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return await db.transaction((txn) async {
      final paymentMap = _stamp(payment.toMap());
      paymentMap.remove('id');
      final id = await txn.insert('customer_payments', paymentMap);

      final customerRows = await txn.query('customers', where: 'id = ?', whereArgs: [payment.customerId], limit: 1);
      if (customerRows.isNotEmpty) {
        final customer = customerRows.first;
        final existingPending = (customer['pendingAmount'] as num?)?.toDouble() ?? 0.0;
        final existingAdvance = (customer['advanceAmount'] as num?)?.toDouble() ?? 0.0;
        final amount = payment.amount;
        final appliedToPending = amount <= existingPending ? amount : existingPending;
        final extraAdvance = amount > existingPending ? amount - existingPending : 0.0;
        await txn.update(
          'customers',
          {
            'pendingAmount': (existingPending - appliedToPending).clamp(0.0, double.infinity),
            'advanceAmount': existingAdvance + extraAdvance,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [payment.customerId],
        );
      }
      return id;
    });
  }

  Future<int> insertSupplierPayment(SupplierPayment payment) async {
    final db = await instance.database;
        FirebaseSyncService.instance.triggerAutoSync();
return await db.transaction((txn) async {
      final paymentMap = _stamp(payment.toMap());
      paymentMap.remove('id');
      final id = await txn.insert('supplier_payments', paymentMap);

      final supplierRows = await txn.query('suppliers', where: 'id = ?', whereArgs: [payment.supplierId], limit: 1);
      if (supplierRows.isNotEmpty) {
        final supplier = supplierRows.first;
        final existingPending = (supplier['pendingAmount'] as num?)?.toDouble() ?? 0.0;
        final existingAdvance = (supplier['advanceAmount'] as num?)?.toDouble() ?? 0.0;
        final amount = payment.amount;
        final appliedToPending = amount <= existingPending ? amount : existingPending;
        final extraAdvance = amount > existingPending ? amount - existingPending : 0.0;
        await txn.update(
          'suppliers',
          {
            'pendingAmount': (existingPending - appliedToPending).clamp(0.0, double.infinity),
            'advanceAmount': existingAdvance + extraAdvance,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [payment.supplierId],
        );
      }
      return id;
    });
  }

  Future<List<Sale>> getSalesForDSS(int dssId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'dss_id = ?',
      whereArgs: [dssId],
      orderBy: 'id DESC',
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  // -- REPORTS -----------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getSalesReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        s.date,
        s.invoice_number,
        COALESCE(s.customer_name, 'Walk-in') AS customer_name,
        s.total,
        s.received,
        s.balance,
        s.payment_method
      FROM sales s
      WHERE date(s.date) BETWEEN date(?) AND date(?)
      ORDER BY s.date DESC
    ''', [fromDate, toDate]);
  }

  Future<List<Map<String, dynamic>>> getProductReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        p.name AS product_name,
        p.category,
        p.stock,
        p.sell_price,
        COALESCE(SUM(si.quantity), 0) AS qty_sold,
        COALESCE(SUM(si.total), 0)    AS revenue
      FROM products p
      LEFT JOIN sale_items si ON si.product_id = p.id
      LEFT JOIN sales s ON s.id = si.sale_id
        AND date(s.date) BETWEEN date(?) AND date(?)
      GROUP BY p.id
      ORDER BY revenue DESC
    ''', [fromDate, toDate]);
  }

  Future<List<Map<String, dynamic>>> getCustomerReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        c.name,
        c.phone,
        COALESCE(SUM(s.total), 0)   AS total_purchases,
        COALESCE(SUM(s.balance), 0) AS outstanding,
        COUNT(s.id)                 AS visit_count
      FROM customers c
      LEFT JOIN sales s ON s.customer_id = c.id
        AND date(s.date) BETWEEN date(?) AND date(?)
      GROUP BY c.id
      ORDER BY total_purchases DESC
    ''', [fromDate, toDate]);
  }

  Future<List<Map<String, dynamic>>> getInventoryReportData() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        name,
        category,
        packaging,
        stock,
        threshold,
        cost_price,
        sell_price,
        ROUND(stock * sell_price, 2) AS stock_value,
        CASE WHEN stock <= threshold THEN 'Low' ELSE 'OK' END AS status
      FROM products
      ORDER BY stock ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPurchaseReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        po.po_number,
        po.supplier,
        po.order_date,
        po.status,
        COALESCE(SUM(poi.quantity * poi.purchase_price), 0) AS total_cost
      FROM purchase_orders po
      LEFT JOIN purchase_order_items poi ON poi.order_id = po.id
      WHERE date(po.order_date) BETWEEN date(?) AND date(?)
      GROUP BY po.id
      ORDER BY po.order_date DESC
    ''', [fromDate, toDate]);
  }

  Future<List<Map<String, dynamic>>> getExpenseReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT date, category, title, amount, notes
      FROM expenses
      WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      ORDER BY date DESC
    ''', [fromDate, toDate]);
  }

  // -- DASHBOARD ---------------------------------------------------------------

  Future<Map<String, dynamic>> getDashboardData() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final monthStart = '${today.substring(0, 7)}-01';

    // Today sales
    final todaySalesRows = await db.rawQuery(
      "SELECT COALESCE(SUM(total), 0.0) as val FROM sales WHERE date(date) = date(?)",
      [today],
    );
    final todaySales = (todaySalesRows.first['val'] as num?)?.toDouble() ?? 0.0;

    // Today returns
    final todayReturnRows = await db.rawQuery(
      "SELECT COALESCE(SUM(total_refund), 0.0) as val FROM sales_returns WHERE date(date) = date(?)",
      [today],
    );
    final todayReturn = (todayReturnRows.first['val'] as num?)?.toDouble() ?? 0.0;

    final todayNetSale = todaySales - todayReturn;

    // Monthly net sale
    final monthlySalesRows = await db.rawQuery(
      "SELECT COALESCE(SUM(total), 0.0) as val FROM sales WHERE date(date) >= date(?)",
      [monthStart],
    );
    final monthlySales = (monthlySalesRows.first['val'] as num?)?.toDouble() ?? 0.0;

    final monthlyReturnRows = await db.rawQuery(
      "SELECT COALESCE(SUM(total_refund), 0.0) as val FROM sales_returns WHERE date(date) >= date(?)",
      [monthStart],
    );
    final monthlyReturn = (monthlyReturnRows.first['val'] as num?)?.toDouble() ?? 0.0;
    final monthlyNetSale = monthlySales - monthlyReturn;

    // Receivables
    final receivablesRows = await db.rawQuery(
      "SELECT COALESCE(SUM(pendingAmount), 0.0) as val FROM customers",
    );
    final receivables = (receivablesRows.first['val'] as num?)?.toDouble() ?? 0.0;

    // Low stock count
    final lowStockRows = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM products WHERE stock <= threshold",
    );
    final lowStockCount = (lowStockRows.first['cnt'] as int?) ?? 0;

    // 7-day trend
    final List<Map<String, dynamic>> trend = [];
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final dayRows = await db.rawQuery(
        "SELECT COALESCE(SUM(total), 0.0) as total FROM sales WHERE date(date) = date(?)",
        [dateStr],
      );
      trend.add({'date': dateStr, 'total': (dayRows.first['total'] as num?)?.toDouble() ?? 0.0});
    }

    // Recent purchase orders
    final recentPOs = await db.rawQuery('''
      SELECT po_number, supplier, order_date,
        COALESCE((SELECT SUM(quantity * purchase_price) FROM purchase_order_items WHERE order_id = purchase_orders.id), 0) AS total
      FROM purchase_orders
      ORDER BY id DESC LIMIT 5
    ''');

    // Recent activity (from ledger: sales, returns, expenses)
    final recentActivity = await db.rawQuery('''
      SELECT date, 'Sale' AS type, invoice_number AS description, total AS amount FROM sales
      UNION ALL
      SELECT date, 'Return' AS type, invoice_number AS description, -total_refund AS amount FROM sales_returns
      UNION ALL
      SELECT date, 'Expense' AS type, title AS description, -amount AS amount FROM expenses
      ORDER BY date DESC LIMIT 5
    ''');

    return {
      'todaySales': todaySales,
      'todayReturn': todayReturn,
      'todayNetSale': todayNetSale,
      'monthlyNetSale': monthlyNetSale,
      'receivables': receivables,
      'lowStockCount': lowStockCount,
      'trend': trend,
      'recentPOs': recentPOs,
      'recentActivity': recentActivity,
    };
  }

  Future<List<Map<String, dynamic>>> getSupplierReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        s.companyName,
        s.contactPerson,
        s.phone,
        COALESCE(s.pendingAmount, 0)  AS pendingAmount,
        COALESCE(s.advanceAmount, 0)  AS advanceAmount,
        COALESCE(SUM(po.paid_amount), 0) AS paid,
        COUNT(po.id) AS order_count
      FROM suppliers s
      LEFT JOIN purchase_orders po ON po.supplier = s.companyName
        AND date(po.order_date) BETWEEN date(?) AND date(?)
      GROUP BY s.id
      ORDER BY COALESCE(s.pendingAmount, 0) DESC
    ''', [fromDate, toDate]);
  }

  Future<List<Map<String, dynamic>>> getLedgerReportData({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT date, 'Sale' AS type, invoice_number AS description, total AS debit, 0 AS credit FROM sales
        WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT date, 'Return' AS type, invoice_number AS description, 0 AS debit, total_refund AS credit FROM sales_returns
        WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT date, 'Expense' AS type, title AS description, 0 AS debit, amount AS credit FROM expenses
        WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      ORDER BY date DESC
    ''', [fromDate, toDate, fromDate, toDate, fromDate, toDate]);
  }

  // -- GENERAL LEDGER ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> getGeneralLedger(DateTime? from, DateTime? to) async {
    final db = await instance.database;
    final f = from?.toIso8601String().substring(0, 10) ?? '1970-01-01';
    final t = to?.toIso8601String().substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10);
    return await db.rawQuery('''
      SELECT date, invoice_number AS title, customer_name AS description, 'Sales' AS category, 'Sale' AS type, received AS debit, 0.0 AS credit, received AS amount FROM sales
        WHERE received > 0 AND date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT date, return_number AS title, customer_name AS description, CASE WHEN invoice_number LIKE 'OSR-%' OR invoice_number LIKE 'OPEN-%' THEN 'Open Return' ELSE 'Sales Return' END AS category, 'Return' AS type, 0.0 AS debit, total_refund AS credit, -total_refund AS amount FROM sales_returns
        WHERE total_refund > 0 AND date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT date, title AS title, notes AS description, category AS category, 'Expense' AS type, 0.0 AS debit, amount AS credit, -amount AS amount FROM expenses
        WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT date, COALESCE(invoice_number, reference) AS title, reference AS description, 'Customer Receipt' AS category, 'Receipt' AS type, amount AS debit, 0.0 AS credit, amount AS amount FROM customer_payments
        WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT date, COALESCE(invoice_number, reference) AS title, reference AS description, 'Supplier Payment' AS category, 'Payment' AS type, 0.0 AS debit, amount AS credit, -amount AS amount FROM supplier_payments
        WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      UNION ALL
      SELECT order_date AS date, po_number AS title, supplier AS description, 'Purchase' AS category, 'Purchase' AS type, 0.0 AS debit, paid_amount AS credit, -paid_amount AS amount FROM purchase_orders
        WHERE paid_amount > 0 AND date(order_date) BETWEEN date(?) AND date(?) AND is_deleted = 0
      ORDER BY date DESC
    ''', [f, t, f, t, f, t, f, t, f, t, f, t]);
  }

  Future<List<Map<String, dynamic>>> getCustomerStatement(String customerId, DateTime? from, DateTime? to) async {
    final db = await instance.database;
    final f = from?.toIso8601String().substring(0, 10) ?? '1970-01-01';
    final t = to?.toIso8601String().substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10);
    final customerRows = await db.query('customers', where: 'id = ?', whereArgs: [customerId], limit: 1);
    if (customerRows.isEmpty) return [];
    final customerName = customerRows.first['name'] as String;
    final transactions = await db.rawQuery('''
      SELECT date, invoice_number AS reference, 'Sale Invoice' AS description, 'Sale' AS type, total AS debit, 0.0 AS credit, 3 AS sort_order
      FROM sales WHERE customer_id = ? AND date(date) BETWEEN date(?) AND date(?)
      UNION ALL
      SELECT date, invoice_number AS reference, 'Advance received at Sale' AS description, 'Sale Payment' AS type, 0.0 AS debit, received AS credit, 0 AS sort_order
      FROM sales WHERE customer_id = ? AND received > 0 AND date(date) BETWEEN date(?) AND date(?)
      UNION ALL
      SELECT date, reference AS reference, 'Payment received' AS description, 'Payment' AS type, 0.0 AS debit, amount AS credit, 1 AS sort_order
      FROM customer_payments WHERE customer_id = ? AND date(date) BETWEEN date(?) AND date(?)
      UNION ALL
      SELECT sr.date, sr.invoice_number AS reference, 'Items returned' AS description, 'Return' AS type, 0.0 AS debit, sr.total_refund AS credit, 2 AS sort_order
      FROM sales_returns sr JOIN sales s ON sr.invoice_number = s.invoice_number
      WHERE s.customer_id = ? AND date(sr.date) BETWEEN date(?) AND date(?)
      UNION ALL
      SELECT sr.date, sr.return_number AS reference, 'Open Return' AS description, 'Return' AS type, 0.0 AS debit, sr.total_refund AS credit, 2 AS sort_order
      FROM sales_returns sr
      WHERE sr.customer_name = ? AND sr.invoice_number LIKE 'OPEN-%' AND date(sr.date) BETWEEN date(?) AND date(?)
    ''', [customerId, f, t, customerId, f, t, customerId, f, t, customerId, f, t, customerName, f, t]);
    
    // Process running balance
    final all = List<Map<String, dynamic>>.from(transactions);
    all.sort((a, b) {
      final dateCmp = (a['date'] as String).compareTo(b['date'] as String);
      if (dateCmp != 0) return dateCmp;
      return (a['sort_order'] as int).compareTo(b['sort_order'] as int);
    });
    double balance = 0.0;
    for (int i = 0; i < all.length; i++) {
      balance += (all[i]['debit'] as num) - (all[i]['credit'] as num);
      all[i] = {...all[i], 'balance': balance};
    }
    final closingBalance = balance;
    // Sort descending for UI
    all.sort((a, b) {
      final dateCmp = (b['date'] as String).compareTo(a['date'] as String);
      if (dateCmp != 0) return dateCmp;
      return (a['sort_order'] as int).compareTo(b['sort_order'] as int);
    });
    balance = closingBalance;
    for (var i = 0; i < all.length; i++) {
      final row = all[i];
      all[i] = {
        ...row,
        'balance': balance,
        'closing_balance': closingBalance,
      };
      balance -= (row['debit'] as num).toDouble() - (row['credit'] as num).toDouble();
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> getSupplierStatement(String supplierId, DateTime? from, DateTime? to) async {
    final db = await instance.database;
    final f = from?.toIso8601String().substring(0, 10) ?? '1970-01-01';
    final t = to?.toIso8601String().substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10);
    // Get supplier name
    final supplier = await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId]);
    if (supplier.isEmpty) return [];
    final name = supplier.first['companyName'] as String;
    
    final transactions = await db.rawQuery('''
      SELECT order_date AS date, po_number AS reference, 'Purchase Order' AS description, 'Purchase' AS type,
        COALESCE((SELECT SUM(quantity * purchase_price) FROM purchase_order_items WHERE order_id = purchase_orders.id), 0) + tax_amount AS debit, 0.0 AS credit, 2 AS sort_order
      FROM purchase_orders WHERE supplier = ? AND date(order_date) BETWEEN date(?) AND date(?)
      UNION ALL
      SELECT order_date AS date, po_number AS reference, 'Payment at Purchase' AS description, 'Purchase Payment' AS type,
        0.0 AS debit, paid_amount AS credit, 1 AS sort_order
      FROM purchase_orders WHERE supplier = ? AND paid_amount > 0 AND date(order_date) BETWEEN date(?) AND date(?)
      UNION ALL
      SELECT date, reference AS reference, 'Payment to Supplier' AS description, 'Payment' AS type, 0.0 AS debit, amount AS credit, 0 AS sort_order
      FROM supplier_payments WHERE supplier_id = ? AND date(date) BETWEEN date(?) AND date(?)
    ''', [name, f, t, name, f, t, supplierId, f, t]);
    
    final all = List<Map<String, dynamic>>.from(transactions);
    all.sort((a, b) {
      final dateCmp = (a['date'] as String).compareTo(b['date'] as String);
      if (dateCmp != 0) return dateCmp;
      return (a['sort_order'] as int).compareTo(b['sort_order'] as int);
    });
    double balance = 0.0;
    for (int i = 0; i < all.length; i++) {
      balance += (all[i]['debit'] as num) - (all[i]['credit'] as num);
      all[i] = {...all[i], 'balance': balance};
    }
    final closingBalance = balance;
    // Sort descending for UI
    all.sort((a, b) {
      final dateCmp = (b['date'] as String).compareTo(a['date'] as String);
      if (dateCmp != 0) return dateCmp;
      return (a['sort_order'] as int).compareTo(b['sort_order'] as int);
    });
    balance = closingBalance;
    for (var i = 0; i < all.length; i++) {
      final row = all[i];
      all[i] = {
        ...row,
        'balance': balance,
        'closing_balance': closingBalance,
      };
      balance -= (row['debit'] as num).toDouble() - (row['credit'] as num).toDouble();
    }
    return all;
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    final map = _stamp(expense.toMap());
    map.remove('id');
        FirebaseSyncService.instance.triggerAutoSync();
return await db.insert('expenses', map);
  }

  // -- SALES (ALL) -------------------------------------------------------------

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final maps = await db.query('sales', orderBy: 'id DESC');
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  // -- SALES RETURNS -----------------------------------------------------------

  Future<List<SalesReturn>> getAllSalesReturns() async {
    final db = await instance.database;
    final maps = await db.query('sales_returns', orderBy: 'id DESC');
    return maps.map((m) => SalesReturn.fromMap(m)).toList();
  }

  Future<int> insertSalesReturn(SalesReturn returnData) async {
    final db = await instance.database;
    int returnId = 0;
    await db.transaction((txn) async {
      final saleRows = await txn.query(
        'sales',
        columns: ['customer_id', 'balance'],
        where: 'invoice_number = ?',
        whereArgs: [returnData.invoiceNumber],
        limit: 1,
      );
      final String? saleCustomerId = saleRows.isNotEmpty ? saleRows.first['customer_id']?.toString() : null;
      final saleBalance = saleRows.isNotEmpty ? (saleRows.first['balance'] as num?)?.toDouble() ?? 0.0 : 0.0;
      final returnAmount = returnData.totalRefund;

      final items = returnData.items;
      final returnMap = returnData.toMap();
      returnMap.remove('id');
      if ((returnMap['return_number']?.toString() ?? '').trim().isEmpty) {
        final nextRows = await txn.rawQuery('SELECT COUNT(*) AS cnt FROM sales_returns');
        final count = (nextRows.first['cnt'] as int?) ?? 0;
        returnMap['return_number'] = 'SR-${(count + 1).toString().padLeft(3, '0')}';
      }
      returnId = await txn.insert('sales_returns', _stamp(returnMap));
      for (final item in items) {
        final itemMap = _stamp(item.toMap());
        itemMap.remove('id');
        itemMap['sales_return_id'] = returnId;
        await txn.insert('sales_return_items', itemMap);
        // Restock
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [item.quantityReturned, item.productId],
        );
      }

      // Update original sale's balance and status
      await txn.rawUpdate(
        'UPDATE sales SET balance = CASE WHEN balance - ? <= 0.01 THEN 0 ELSE balance - ? END, status = CASE WHEN balance - ? <= 0.01 THEN \'Paid\' ELSE status END WHERE invoice_number = ?',
        [returnAmount, returnAmount, returnAmount, returnData.invoiceNumber],
      );

      if (saleCustomerId?.isNotEmpty == true && saleBalance > 0) {
        await txn.rawUpdate(
          'UPDATE customers SET pendingAmount = CASE WHEN pendingAmount - ? <= 0.01 THEN 0 ELSE pendingAmount - ? END WHERE id = ?',
          [returnAmount, returnAmount, saleCustomerId],
        );
      }
    });
    FirebaseSyncService.instance.triggerAutoSync();
    return returnId;
  }

  Future<String> getNextOpenReturnInvoiceNumber() async {
    final db = await instance.database;
    final nextRows = await db.rawQuery("SELECT COUNT(*) AS cnt FROM sales_returns WHERE invoice_number LIKE 'OSR-%' OR invoice_number LIKE 'OPEN-%'");
    final count = (nextRows.first['cnt'] as int?) ?? 0;
    return 'OSR-${(count + 1).toString().padLeft(3, '0')}';
  }

  Future<List<SalesReturnItem>> getReturnItems(int returnId) async {
    final db = await instance.database;
    final maps = await db.query('sales_return_items', where: 'sales_return_id = ?', whereArgs: [returnId]);
    return maps.map((m) => SalesReturnItem.fromMap(m)).toList();
  }

  Future<int> deleteSalesReturn(int id) async {
    final db = await instance.database;
    FirebaseSyncService.instance.triggerAutoSync();
    return db.delete('sales_returns', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSalesReturn(SalesReturn returnData) async {
    final db = await instance.database;
    final map = returnData.toMap();
    final id = returnData.id;
    if (id == null) {
      throw ArgumentError('Sales return id is required for update.');
    }
    map.remove('id');
    FirebaseSyncService.instance.triggerAutoSync();
    return db.update('sales_returns', map, where: 'id = ?', whereArgs: [id]);
  }

  // -- DEBUGGING ---------------------------------------------------------------
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final tables = [
        'sales_return_items',
        'sales_returns',
        'sale_items',
        'sales',
        'daily_sales_sheets',
        'expenses',
        'supplier_payments',
        'customer_payments',
        'purchase_order_items',
        'purchase_orders',
        'products',
        'customers',
        'suppliers',
      ];
      for (final table in tables) {
        await txn.delete(table);
      }
    });
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

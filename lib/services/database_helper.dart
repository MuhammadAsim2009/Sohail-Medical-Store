import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../models/supplier.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 4,
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
  paid_amount REAL NOT NULL DEFAULT 0.0
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
  }

  Future _createDB(Database db, int version) async {
    await db.execute("""
CREATE TABLE IF NOT EXISTS products (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
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
  po_number   TEXT UNIQUE NOT NULL,
  supplier    TEXT NOT NULL,
  order_date  TEXT NOT NULL,
  status      TEXT NOT NULL,
  notes       TEXT,
  tax_rate    REAL NOT NULL DEFAULT 0.0,
  paid_amount REAL NOT NULL DEFAULT 0.0
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

  // ── PRODUCTS ────────────────────────────────────────────────────────────────

  Future<Product> insertProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert('products', product.toMap());
    product.id = id;
    return product;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
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
      await txn.update('products', {'stock': newStock},
          where: 'id = ?', whereArgs: [product.id]);
      await txn.insert('purchase_history', {
        'product_id': product.id,
        'purchase_date': DateTime.now().toIso8601String(),
        'unit_purchased': unitPurchased,
        'quantity': qtyPurchased,
        'cost_price': costPerUnit,
        'total_cost': qtyPurchased * costPerUnit,
      });
    });
  }

  // ── PURCHASE ORDERS ─────────────────────────────────────────────────────────

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
      final orderId = await txn.insert('purchase_orders', {
        'po_number': poNumber,
        'supplier': order.supplier,
        'order_date': order.orderDate.toIso8601String(),
        'status': order.status,
        'notes': order.notes,
        'tax_rate': order.taxRate,
        'paid_amount': order.paidAmount,
      });
      final savedItems = <PurchaseOrderItem>[];
      for (final item in order.items) {
        final itemId = await txn.insert('purchase_order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_purchased': item.unitPurchased,
          'quantity': item.quantity,
          'purchase_price': item.purchasePrice,
          'selling_price': item.sellingPrice,
          'discount': item.discount,
          'expiry_date': item.expiryDate?.toIso8601String(),
        });
        savedItems.add(item.copyWith(id: itemId));
      }
      saved = order.copyWith(id: orderId, poNumber: poNumber, items: savedItems);
    });
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
    await db.update('purchase_orders', {'status': status},
        where: 'id = ?', whereArgs: [orderId]);
  }

  Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'purchase_orders',
        {
          'supplier': order.supplier,
          'notes': order.notes,
          'tax_rate': order.taxRate,
          'paid_amount': order.paidAmount,
          'status': order.status,
        },
        where: 'id = ?',
        whereArgs: [order.id],
      );
      await txn.delete('purchase_order_items',
          where: 'order_id = ?', whereArgs: [order.id]);
      for (final item in order.items) {
        await txn.insert('purchase_order_items', {
          'order_id': order.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit_purchased': item.unitPurchased,
          'quantity': item.quantity,
          'purchase_price': item.purchasePrice,
          'selling_price': item.sellingPrice,
          'discount': item.discount,
          'expiry_date': item.expiryDate?.toIso8601String(),
        });
      }
    });
  }

  /// Mark as Received and atomically credit inventory stock.
  Future<void> receivePurchaseOrder(PurchaseOrder order) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update('purchase_orders', {'status': 'Received'},
          where: 'id = ?', whereArgs: [order.id]);
      for (final item in order.items) {
        if (item.productId == null) continue;
        final rows = await txn.query('products',
            where: 'id = ?', whereArgs: [item.productId]);
        if (rows.isEmpty) continue;
        final product = Product.fromMap(rows.first);
        final multiplier = product.getMultiplier(item.unitPurchased);
        final newStock = product.stock + item.quantity * multiplier;

        // Always update stock; update prices only if non-zero values were entered
        // This way new products get their prices set on first purchase,
        // and re-purchased items update to latest prices.
        // Prices from purchase order are per unitPurchased, so divide by multiplier for base unit.
        final Map<String, dynamic> updateMap = {'stock': newStock};
        if (item.purchasePrice > 0) updateMap['cost_price'] = item.purchasePrice / multiplier;
        if (item.sellingPrice > 0)  updateMap['sell_price'] = item.sellingPrice / multiplier;

        await txn.update('products', updateMap,
            where: 'id = ?', whereArgs: [item.productId]);
        await txn.insert('purchase_history', {
          'product_id': item.productId,
          'purchase_date': DateTime.now().toIso8601String(),
          'unit_purchased': item.unitPurchased,
          'quantity': item.quantity,
          'cost_price': item.purchasePrice,
          'total_cost': item.quantity * item.purchasePrice,
        });
      }
    });
  }

  // ── SUPPLIERS ────────────────────────────────────────────────────────────────

  Future<void> insertSupplier(Supplier supplier) async {
    final db = await instance.database;
    await db.insert(
      'suppliers',
      supplier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Supplier>> getSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;
    return db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(String id) async {
    final db = await instance.database;
    return db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

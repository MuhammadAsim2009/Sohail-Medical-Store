import os

file_path = 'd:/pharmacy/lib/services/database_helper.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update DB Version
content = content.replace('version: 27,', 'version: 28,')

# 2. Add Migration for 28
old_migration = """    if (oldVersion < 27) {
      try { await db.execute('ALTER TABLE purchase_order_items ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
      try { await db.execute('ALTER TABLE purchase_orders ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
      try { await db.execute('ALTER TABLE product_batches ADD COLUMN discount REAL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE product_batches ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
    }"""
new_migration = old_migration + """
    if (oldVersion < 28) {
      try { await db.execute('ALTER TABLE sale_items ADD COLUMN batch_id INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE sale_items ADD COLUMN discount REAL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE sale_items ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
    }"""
content = content.replace(old_migration, new_migration)

# 3. Add to createDB for sale_items
create_table_old = """CREATE TABLE IF NOT EXISTS sale_items (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id         TEXT UNIQUE,
  updated_at      INTEGER,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  sale_id         INTEGER NOT NULL,
  product_id      INTEGER NOT NULL,
  product_name    TEXT NOT NULL,
  quantity        INTEGER NOT NULL,
  price           REAL NOT NULL,
  gst             REAL NOT NULL DEFAULT 0.0,
  total           REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
)"""
create_table_new = """CREATE TABLE IF NOT EXISTS sale_items (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sync_id         TEXT UNIQUE,
  updated_at      INTEGER,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  sale_id         INTEGER NOT NULL,
  product_id      INTEGER NOT NULL,
  product_name    TEXT NOT NULL,
  quantity        INTEGER NOT NULL,
  price           REAL NOT NULL,
  gst             REAL NOT NULL DEFAULT 0.0,
  total           REAL NOT NULL,
  batch_id        INTEGER,
  discount        REAL DEFAULT 0.0,
  discount_type   TEXT DEFAULT "Rupee",
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
)"""
content = content.replace(create_table_old, create_table_new)

# 4. Update insertSale
old_insert_fefo = """          // FEFO: deduct from batches ordered by earliest expiry first
          double remaining = (item.quantity as num).toDouble();
          final batches = await txn.rawQuery(
            'SELECT id, batch_quantity FROM product_batches '
            'WHERE product_id = ? AND batch_quantity > 0 AND is_deleted = 0 '
            'ORDER BY (expiry_date IS NULL) ASC, expiry_date ASC',
            [item.productId],
          );
          for (final batch in batches) {
            if (remaining <= 0) break;
            final batchId = batch['id'] as int;
            final batchQty = (batch['batch_quantity'] as num).toDouble();
            final deduct = remaining <= batchQty ? remaining : batchQty;
            await txn.rawUpdate(
              'UPDATE product_batches SET batch_quantity = batch_quantity - ?, updated_at = ?, is_dirty = 1 WHERE id = ?',
              [deduct, DateTime.now().millisecondsSinceEpoch, batchId],
            );
            remaining -= deduct;
          }"""
new_insert_fefo = """          double remaining = (item.quantity as num).toDouble();

          // If a specific batch was selected, deduct from it first
          if (item.batchId != null) {
            final specificBatch = await txn.rawQuery(
              'SELECT batch_quantity FROM product_batches WHERE id = ?',
              [item.batchId],
            );
            if (specificBatch.isNotEmpty) {
              final batchQty = (specificBatch.first['batch_quantity'] as num).toDouble();
              final deduct = remaining <= batchQty ? remaining : batchQty;
              await txn.rawUpdate(
                'UPDATE product_batches SET batch_quantity = batch_quantity - ?, updated_at = ?, is_dirty = 1 WHERE id = ?',
                [deduct, DateTime.now().millisecondsSinceEpoch, item.batchId],
              );
              remaining -= deduct;
            }
          }

          // FEFO for any remaining quantity
          if (remaining > 0) {
            final batches = await txn.rawQuery(
              'SELECT id, batch_quantity FROM product_batches '
              'WHERE product_id = ? AND batch_quantity > 0 AND is_deleted = 0 '
              'ORDER BY (expiry_date IS NULL) ASC, expiry_date ASC',
              [item.productId],
            );
            for (final batch in batches) {
              if (remaining <= 0) break;
              final batchId = batch['id'] as int;
              final batchQty = (batch['batch_quantity'] as num).toDouble();
              final deduct = remaining <= batchQty ? remaining : batchQty;
              await txn.rawUpdate(
                'UPDATE product_batches SET batch_quantity = batch_quantity - ?, updated_at = ?, is_dirty = 1 WHERE id = ?',
                [deduct, DateTime.now().millisecondsSinceEpoch, batchId],
              );
              remaining -= deduct;
            }
          }"""
content = content.replace(old_insert_fefo, new_insert_fefo)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated database_helper.dart')

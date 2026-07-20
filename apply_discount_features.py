import re
import os

def update_purchase_order_model():
    file_path = 'd:/pharmacy/lib/models/purchase_order.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Add discountType to PurchaseOrderItem
    content = re.sub(
        r'(final double discount;)(\s*)(final double gst;)',
        r'\1\2final String discountType;\2\3',
        content
    )
    content = re.sub(
        r'(this.discount = 0.0,)',
        r'\1\n    this.discountType = \'Rupee\',',
        content
    )
    content = re.sub(
        r'(double get subtotal => \(quantity \* purchasePrice \* \(1 \+ \(gst \/ 100\)\)\) - discount;)',
        r'double get subtotal {\n    final base = quantity * purchasePrice * (1 + (gst / 100));\n    final disc = discountType == \'Percentage\' ? base * (discount / 100) : discount;\n    return base - disc;\n  }',
        content
    )
    content = re.sub(
        r'(double\? discount,)',
        r'\1\n    String? discountType,',
        content
    )
    content = re.sub(
        r'(discount: discount \?\? this\.discount,)',
        r'\1\n      discountType: discountType ?? this.discountType,',
        content
    )
    content = re.sub(
        r'(discount: \(map\[\'discount\'\] as num\)\.toDouble\(\),)',
        r'\1\n      discountType: map[\'discount_type\'] as String? ?? \'Rupee\',',
        content
    )
    content = re.sub(
        r'(\'discount\': discount,)',
        r'\1\n      \'discount_type\': discountType,',
        content
    )
    
    # Add discountType to PurchaseOrder
    content = re.sub(
        r'(final double discount;)(\s*)(final String status;)',
        r'\1\2final String discountType;\2\3',
        content
    )
    content = re.sub(
        r'(this.discount = 0.0,)(\s*)(required this.status,)',
        r'\1\2this.discountType = \'Rupee\',\2\3',
        content
    )
    content = re.sub(
        r'(double\? discount,)(\s*)(String\? status,)',
        r'\1\2String? discountType,\2\3',
        content
    )
    content = re.sub(
        r'(discount: discount \?\? this\.discount,)(\s*)(status: status \?\? this\.status,)',
        r'\1\2discountType: discountType ?? this.discountType,\2\3',
        content
    )
    content = re.sub(
        r'(discount: \(map\[\'discount\'\] as num\?\)\?\.toDouble\(\) \?\? 0\.0,)(\s*)(status: map\[\'status\'\] as String,)',
        r'\1\2discountType: map[\'discount_type\'] as String? ?? \'Rupee\',\2\3',
        content
    )
    # the second occurrence of 'discount': discount in the toMap of PurchaseOrder
    # We can do a string replace since it occurs twice in the file
    content = content.replace(
        "      'discount': discount,\n      'status': status,",
        "      'discount': discount,\n      'discount_type': discountType,\n      'status': status,"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated PurchaseOrder model.")

def update_database_helper():
    file_path = 'd:/pharmacy/lib/services/database_helper.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Bump version
    content = re.sub(r'version: 26,', r'version: 27,', content)
    
    # Update _upgradeDB
    upgrade_snippet = """    if (oldVersion < 27) {
      try { await db.execute('ALTER TABLE purchase_order_items ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
      try { await db.execute('ALTER TABLE purchase_orders ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
      try { await db.execute('ALTER TABLE product_batches ADD COLUMN discount REAL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE product_batches ADD COLUMN discount_type TEXT DEFAULT "Rupee"'); } catch (_) {}
    }"""
    content = re.sub(
        r'(if \(oldVersion < 26\) \{)',
        upgrade_snippet + r'\n    \1',
        content
    )
    
    # Update _createDB
    # purchase_orders
    content = re.sub(
        r'(discount    REAL DEFAULT 0.0,)',
        r'\1\n  discount_type TEXT DEFAULT "Rupee",',
        content
    )
    # purchase_order_items
    content = re.sub(
        r'(discount       REAL DEFAULT 0.0,)',
        r'\1\n  discount_type  TEXT DEFAULT "Rupee",',
        content
    )
    # product_batches
    content = re.sub(
        r'(is_dirty          INTEGER NOT NULL DEFAULT 1)',
        r'\1,\n  discount          REAL DEFAULT 0.0,\n  discount_type     TEXT DEFAULT "Rupee"',
        content
    )
    content = re.sub(
        r'(\'is_dirty\': 1,)',
        r'\1\n            \'discount\': 0.0,\n            \'discount_type\': \'Rupee\',',
        content
    )
    
    # Update receivePurchaseOrder (batch creation)
    content = re.sub(
        r'(\'is_dirty\': 1,)(\s*)(\}\);)(\s*)(// Update product stock)',
        r'\1\2\'discount\': item.discount,\2\'discount_type\': item.discountType,\2\3\4\5',
        content
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated DatabaseHelper.")

update_purchase_order_model()
update_database_helper()

import os
import re

ui_path = r"lib\screens\purchase_orders_screen.dart"
with open(ui_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _ItemRow class properties
old_item_row = '''class _ItemRow {
  Product product;
  String unitPurchased;
  double quantity;
  double purchasePrice;
  double sellingPrice;
  double gst;
  DateTime? expiryDate;

  _ItemRow({
    required this.product,
    required this.unitPurchased,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.gst = 0.0,
    this.expiryDate,
  });
}'''
new_item_row = '''class _ItemRow {
  Product product;
  String unitPurchased;
  double quantity;
  double purchasePrice;
  double sellingPrice;
  double gst;
  double discount;
  String discountType;
  DateTime? expiryDate;

  _ItemRow({
    required this.product,
    required this.unitPurchased,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.gst = 0.0,
    this.discount = 0.0,
    this.discountType = 'Rupee',
    this.expiryDate,
  });
}'''
content = content.replace(old_item_row, new_item_row)

# 2. Update _PurchaseOrderDialogState map to _ItemRow
old_map_to_row = '''            sellingPrice: i.sellingPrice,
            gst: i.gst,
            expiryDate: i.expiryDate,
          );'''
new_map_to_row = '''            sellingPrice: i.sellingPrice,
            gst: i.gst,
            discount: i.discount,
            discountType: i.discountType,
            expiryDate: i.expiryDate,
          );'''
content = content.replace(old_map_to_row, new_map_to_row)

# 3. Update map back to PurchaseOrderItem
old_map_to_item = '''              purchasePrice: r.purchasePrice,
              sellingPrice: r.sellingPrice,
              discount: 0.0,
              gst: r.gst,
              expiryDate: r.expiryDate,'''
new_map_to_item = '''              purchasePrice: r.purchasePrice,
              sellingPrice: r.sellingPrice,
              discount: r.discount,
              discountType: r.discountType,
              gst: r.gst,
              expiryDate: r.expiryDate,'''
content = content.replace(old_map_to_item, new_map_to_item)

# 4. Update _subtotal logic
old_subtotal = '''  double get _subtotal => _items.fold(
    0.0,
    (s, i) => s + (i.quantity * i.purchasePrice * (1 + i.gst / 100)),
  );'''
new_subtotal = '''  double get _subtotal => _items.fold(
    0.0,
    (s, i) {
      final base = i.quantity * i.purchasePrice * (1 + i.gst / 100);
      final disc = i.discountType == 'Percentage' ? base * (i.discount / 100) : i.discount;
      return s + (base - disc);
    },
  );'''
content = content.replace(old_subtotal, new_subtotal)

# 5. Add UI logic in _ItemCardState
old_init_state = '''    _gstCtrl = TextEditingController(text: widget.row.gst.toString());
    _expiryCtrl = TextEditingController('''
new_init_state = '''    _gstCtrl = TextEditingController(text: widget.row.gst.toString());
    _discountCtrl = TextEditingController(text: widget.row.discount.toString());
    _expiryCtrl = TextEditingController('''
content = content.replace(old_init_state, new_init_state)

old_ctrl_def = '''  late final TextEditingController _gstCtrl;
  late final TextEditingController _expiryCtrl;'''
new_ctrl_def = '''  late final TextEditingController _gstCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _expiryCtrl;'''
content = content.replace(old_ctrl_def, new_ctrl_def)

old_dispose = '''    _gstCtrl.dispose();
    _expiryCtrl.dispose();'''
new_dispose = '''    _gstCtrl.dispose();
    _discountCtrl.dispose();
    _expiryCtrl.dispose();'''
content = content.replace(old_dispose, new_dispose)

# 6. Add UI fields in Row 3 (just before Final Sell Price)
old_row3 = '''                    // Show the GST-inclusive preview
                    Expanded(
                      child: _LabelField(
                        label: 'Final Sell Price',
                        child: Container('''
new_row3 = '''                    // Discount
                    Expanded(
                      child: _LabelField(
                        label: 'Discount',
                        child: TextFormField(
                          controller: _discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.discount = double.tryParse(v) ?? 0;
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Discount Type
                    Expanded(
                      child: _LabelField(
                        label: 'Type',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: r.discountType,
                              isExpanded: true,
                              items: ['Rupee', 'Percentage'].map((t) {
                                return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => r.discountType = v);
                                  widget.onChanged();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Show the GST-inclusive preview
                    Expanded(
                      child: _LabelField(
                        label: 'Final Sell Price',
                        child: Container('''
content = content.replace(old_row3, new_row3)

with open(ui_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Now for database_helper.dart
db_path = r"lib\services\database_helper.dart"
with open(db_path, 'r', encoding='utf-8') as f:
    db_content = f.read()

# Fix create batch hardcoded discount (at lines ~433 and 1239 and 2252)

# Case 1: migration opening batches
old_db1 = """            'is_dirty': 1,
            'discount': 0.0,
            'discount_type': 'Rupee',
          });"""
new_db1 = """            'is_dirty': 1,
            'discount': expiryRows.isNotEmpty ? (expiryRows.first['discount'] as num?)?.toDouble() ?? 0.0 : 0.0,
            'discount_type': expiryRows.isNotEmpty ? (expiryRows.first['discount_type'] as String?) ?? 'Rupee' : 'Rupee',
          });"""
db_content = db_content.replace(old_db1, new_db1)

old_db_query = """          'SELECT poi.expiry_date FROM purchase_order_items poi '"""
new_db_query = """          'SELECT poi.expiry_date, poi.discount, poi.discount_type FROM purchase_order_items poi '"""
db_content = db_content.replace(old_db_query, new_db_query)

# Case 2: purchase order batch insertion
old_db2 = """            'is_deleted': 0,
            'is_dirty': 1,
            'discount': 0.0,
            'discount_type': 'Rupee',
          },
        );"""
new_db2 = """            'is_deleted': 0,
            'is_dirty': 1,
            'discount': item.discount,
            'discount_type': item.discountType,
          },
        );"""
db_content = db_content.replace(old_db2, new_db2)

# Case 3: sales return missing batch insertion
old_db3 = """              'is_deleted': 0,
              'is_dirty': 1,
            'discount': 0.0,
            'discount_type': 'Rupee',
            });"""
new_db3 = """              'is_deleted': 0,
              'is_dirty': 1,
              'discount': 0.0,
              'discount_type': 'Rupee',
            });"""
db_content = db_content.replace(old_db3, new_db3)


with open(db_path, 'w', encoding='utf-8') as f:
    f.write(db_content)
print("Done!")

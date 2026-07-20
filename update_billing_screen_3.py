import os

file_path = 'd:/pharmacy/lib/screens/billing_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _CartItem
old_cart_item = """class _CartItem {
  final Product product;
  String unit;
  int unitQty;
  double pricePerUnit;
  double gst;

  _CartItem({
    required this.product,
    required this.unit,
    required this.unitQty,
    required this.pricePerUnit,
    this.gst = 0.0,
  });

  double get total => (unitQty * pricePerUnit) * (1 + (gst / 100));
}"""
new_cart_item = """class _CartItem {
  final Product product;
  String unit;
  int unitQty;
  double pricePerUnit;
  double gst;
  
  int? batchId;
  double purchaseDiscount;
  String purchaseDiscountType;
  double customerDiscount;

  _CartItem({
    required this.product,
    required this.unit,
    required this.unitQty,
    required this.pricePerUnit,
    this.gst = 0.0,
    this.batchId,
    this.purchaseDiscount = 0.0,
    this.purchaseDiscountType = 'Rupee',
    this.customerDiscount = 0.0,
  });

  double get total => ((unitQty * pricePerUnit) * (1 + (gst / 100))) - customerDiscount;
}"""
content = content.replace(old_cart_item, new_cart_item)


# 2. Add properties to state
old_props = """  final TextEditingController _receivedController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _stagedGstController = TextEditingController(
    text: '0',
  );
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );"""
new_props = """  final TextEditingController _receivedController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _stagedGstController = TextEditingController(text: '0');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _customerDiscountController = TextEditingController(text: '0');
  
  List<Map<String, dynamic>> _stagedBatches = [];
  Map<String, dynamic>? _selectedBatch;"""
content = content.replace(old_props, new_props)

old_dispose = """    _qtyController.dispose();
    _stagedGstController.dispose();
    _discountController.dispose();"""
new_dispose = """    _qtyController.dispose();
    _stagedGstController.dispose();
    _discountController.dispose();
    _customerDiscountController.dispose();"""
content = content.replace(old_dispose, new_dispose)


# 3. Update _stageProduct
old_stage = """  void _stageProduct(Product p) {
    setState(() {
      _stagedProduct = p;
      _stagedUnit = p.packaging.isNotEmpty ? p.packaging.first.name : 'Unit';
      _qtyController.text = '1';
      _stagedQty = 1;
      _stagedGstController.text = '0';
      _stagedError = null;
    });
  }"""
new_stage = """  Future<void> _stageProduct(Product p) async {
    final batches = await DatabaseHelper.instance.getBatchesForProduct(p.id!);
    setState(() {
      _stagedProduct = p;
      _stagedBatches = batches;
      if (batches.isNotEmpty) {
        _selectedBatch = batches.first;
      } else {
        _selectedBatch = null;
      }
      _customerDiscountController.text = '0';
      _stagedUnit = p.packaging.isNotEmpty ? p.packaging.first.name : 'Unit';
      _qtyController.text = '1';
      _stagedQty = 1;
      _stagedGstController.text = '0';
      _stagedError = null;
    });
  }"""
content = content.replace(old_stage, new_stage)

# 4. In Autocomplete onSelected, _stageProduct is called:
content = content.replace('_stageProduct(p);', '_stageProduct(p);') # Remains the same, but it's now async. Since it's void returning inside a callback, it's fine.


# 5. Add Batch dropdown + discount to staging area
old_staging_bottom = """                                // GST field
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _stagedGstController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText: 'GST %',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),"""
new_staging_bottom = """                                // GST field
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _stagedGstController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText: 'GST %',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_stagedBatches.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<Map<String, dynamic>>(
                                      value: _selectedBatch,
                                      isDense: true,
                                      decoration: InputDecoration(
                                        labelText: 'Select Batch',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      ),
                                      items: _stagedBatches.map((b) {
                                        final bDisc = (b['discount'] as num?)?.toDouble() ?? 0.0;
                                        final bDiscType = b['discount_type'] as String? ?? 'Rupee';
                                        final discText = bDisc > 0 ? ' - Disc: $bDisc ${bDiscType == 'Percentage' ? '%' : 'Rs'}' : '';
                                        return DropdownMenuItem(
                                          value: b,
                                          child: Text('Batch ${b['id']} (Qty: ${b['batch_quantity']})$discText'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedBatch = val;
                                          _customerDiscountController.text = '0';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (_selectedBatch != null && ((_selectedBatch!['discount'] as num?)?.toDouble() ?? 0.0) > 0)
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _customerDiscountController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Cust Disc (Rs.)',
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],"""
content = content.replace(old_staging_bottom, new_staging_bottom)


# 6. Update _addStagedToCart
old_add_cart = """    setState(() {
      _cart.add(
        _CartItem(
          product: _stagedProduct!,
          unit: _stagedUnit,
          unitQty: _stagedQty,
          pricePerUnit: pPrice,
          gst: gst,
        ),
      );"""
new_add_cart = """    double custDisc = double.tryParse(_customerDiscountController.text) ?? 0.0;
    double purDisc = 0.0;
    String purDiscType = 'Rupee';
    int? bId;
    if (_selectedBatch != null) {
      bId = _selectedBatch!['id'] as int;
      purDisc = (_selectedBatch!['discount'] as num?)?.toDouble() ?? 0.0;
      purDiscType = _selectedBatch!['discount_type'] as String? ?? 'Rupee';
      
      // Calculate max allowed discount in rupees based on purchase discount
      double maxAllowed = 0.0;
      double basePrice = (pPrice * _stagedQty);
      if (purDiscType == 'Percentage') {
        maxAllowed = basePrice * (purDisc / 100);
      } else {
        // If purchase discount was Rs X per unit
        maxAllowed = purDisc * _stagedQty;
      }
      if (custDisc > maxAllowed) custDisc = maxAllowed;
    }

    setState(() {
      _cart.add(
        _CartItem(
          product: _stagedProduct!,
          unit: _stagedUnit,
          unitQty: _stagedQty,
          pricePerUnit: pPrice,
          gst: gst,
          batchId: bId,
          purchaseDiscount: purDisc,
          purchaseDiscountType: purDiscType,
          customerDiscount: custDisc,
        ),
      );"""
content = content.replace(old_add_cart, new_add_cart)


# 7. Update Cart List View to show discount if any
old_cart_subtitle = """                                    Text(
                                      'Qty: ${item.unitQty} | Unit Price: Rs. ${item.pricePerUnit.toStringAsFixed(2)} | GST: ${item.gst}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),"""
new_cart_subtitle = """                                    Text(
                                      'Qty: ${item.unitQty} | Unit Price: Rs. ${item.pricePerUnit.toStringAsFixed(2)} | GST: ${item.gst}%' + (item.customerDiscount > 0 ? ' | Disc: -Rs. ${item.customerDiscount.toStringAsFixed(2)}' : ''),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),"""
content = content.replace(old_cart_subtitle, new_cart_subtitle)


# 8. Update Invoice Discount UI (Radio buttons)
old_invoice_discount_ui = """                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Discount Value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),"""
new_invoice_discount_ui = """                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _discountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Discount Value',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Percentage',
                                    groupValue: _discountType,
                                    onChanged: (v) {
                                      if (v != null) setState(() => _discountType = v);
                                    },
                                  ),
                                  const Text('%', style: TextStyle(fontSize: 12)),
                                  Radio<String>(
                                    value: 'Rupees',
                                    groupValue: _discountType,
                                    onChanged: (v) {
                                      if (v != null) setState(() => _discountType = v);
                                    },
                                  ),
                                  const Text('Rs.', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),"""
content = content.replace(old_invoice_discount_ui, new_invoice_discount_ui)

# 9. Update _save()
old_save_mapping = """      final items =
          _cart.map((c) {
            final multiplier = c.product.getMultiplier(c.unit);
            final baseQty = c.unitQty * multiplier;
            return SaleItem(
              productId: c.product.id!,
              productName: c.product.name,
              quantity: baseQty,
              price: c.pricePerUnit / multiplier,
              gst: c.gst,
              total: c.total,
            );
          }).toList();"""
new_save_mapping = """      final items =
          _cart.map((c) {
            final multiplier = c.product.getMultiplier(c.unit);
            final baseQty = c.unitQty * multiplier;
            return SaleItem(
              productId: c.product.id!,
              productName: c.product.name,
              quantity: baseQty,
              price: c.pricePerUnit / multiplier,
              gst: c.gst,
              total: c.total,
              batchId: c.batchId,
              discount: c.customerDiscount,
              discountType: 'Rupee', // customer discount is always rupees here
            );
          }).toList();"""
content = content.replace(old_save_mapping, new_save_mapping)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated billing screen")

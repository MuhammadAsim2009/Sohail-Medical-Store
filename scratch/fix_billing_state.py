import sys
import re

with open('lib/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add state variables to _NewSaleDialogState
state_vars_patch = """
  // Staging: product selected from autocomplete, awaiting unit+qty confirmation
  Product? _stagedProduct;
  String? _stagedUnit;
  int _stagedQty = 1;

  List<Map<String, dynamic>> _stagedBatches = [];
  Map<String, dynamic>? _selectedBatch;
  final TextEditingController _stagedDiscountController = TextEditingController(text: '0');
"""

content = content.replace("""  // Staging: product selected from autocomplete, awaiting unit+qty confirmation
  Product? _stagedProduct;
  String? _stagedUnit;
  int _stagedQty = 1;""", state_vars_patch)


# 2. Modify _stageProduct to load batches
stage_product_original = """  void _stageProduct(Product p) {
    setState(() {
      _stagedProduct = p;
      _stagedUnit = p.packaging.isNotEmpty ? p.packaging.first.name : null;
      _stagedQty = 1;
      _qtyController.text = '1';
      _stagedGstController.text = p.gst
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
      if (_stagedGstController.text.isEmpty) _stagedGstController.text = '0';
    });
  }"""

stage_product_new = """  Future<void> _stageProduct(Product p) async {
    setState(() {
      _stagedProduct = p;
      _stagedUnit = p.packaging.isNotEmpty ? p.packaging.first.name : null;
      _stagedQty = 1;
      _qtyController.text = '1';
      _stagedGstController.text = p.gst
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
      if (_stagedGstController.text.isEmpty) _stagedGstController.text = '0';
      _stagedBatches = [];
      _selectedBatch = null;
      _stagedDiscountController.text = '0';
    });
    final dbHelper = DatabaseHelper.instance;
    final batches = await dbHelper.getInventoryForProduct(p.id!);
    if (mounted && _stagedProduct?.id == p.id) {
      setState(() {
        _stagedBatches = batches.where((b) => (b['batch_quantity'] as num).toDouble() > 0).toList();
      });
    }
  }"""

content = content.replace(stage_product_original, stage_product_new)

# 3. Add to _addStagedToCart
add_staged_original = """    setState(() {
      _cart.add(_CartItem(
        product: _stagedProduct!,
        unit: _stagedUnit!,
        unitQty: _stagedQty,
        pricePerUnit: _stagedPricePerUnit,
        gst: double.tryParse(_stagedGstController.text) ?? 0.0,
      ));
      _stagedProduct = null;
    });"""

add_staged_new = """    setState(() {
      final double batchDisc = (_selectedBatch != null && _selectedBatch!['discount'] != null)
          ? (_selectedBatch!['discount'] as num).toDouble()
          : 0.0;
      final String batchDiscType = (_selectedBatch != null && _selectedBatch!['discount_type'] != null)
          ? _selectedBatch!['discount_type'] as String
          : 'Rupee';
      _cart.add(_CartItem(
        product: _stagedProduct!,
        unit: _stagedUnit!,
        unitQty: _stagedQty,
        pricePerUnit: _stagedPricePerUnit,
        gst: double.tryParse(_stagedGstController.text) ?? 0.0,
        batchId: _selectedBatch?['id'] as int?,
        discount: double.tryParse(_stagedDiscountController.text) ?? 0.0,
        discountType: batchDiscType,
        maxDiscount: batchDisc,
      ));
      _stagedProduct = null;
    });"""

content = content.replace(add_staged_original, add_staged_new)


with open('lib/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

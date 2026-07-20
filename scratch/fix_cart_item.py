import sys

with open('lib/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _CartItem definition at the end
old_cart_item = """class _CartItem {
  final Product product;
  final String unit;
  int unitQty; // quantity in the selected unit
  final double pricePerUnit; // price per selected unit
  double gst; // GST percentage

  _CartItem({
    required this.product,
    required this.unit,
    required this.unitQty,
    required this.pricePerUnit,
    this.gst = 0.0,
  });

  double get total => (pricePerUnit * unitQty) * (1 + (gst / 100));

  /// Base units to deduct from stock
  int get baseUnits => unitQty * product.getMultiplier(unit);
}
"""

new_cart_item = """class _CartItem {
  final Product product;
  final String unit;
  int unitQty; // quantity in the selected unit
  final double pricePerUnit; // price per selected unit
  double gst; // GST percentage
  final int? batchId;
  final double discount;
  final String discountType;
  final double maxDiscount;

  _CartItem({
    required this.product,
    required this.unit,
    required this.unitQty,
    required this.pricePerUnit,
    this.gst = 0.0,
    this.batchId,
    this.discount = 0.0,
    this.discountType = 'Rupee',
    this.maxDiscount = 0.0,
  });

  double get total {
    final base = pricePerUnit * unitQty;
    final withGst = base * (1 + (gst / 100));
    if (discountType == 'Percentage') {
      return withGst - (withGst * (discount / 100));
    } else {
      return withGst - (discount * unitQty);
    }
  }

  /// Base units to deduct from stock
  int get baseUnits => unitQty * product.getMultiplier(unit);
}
"""

content = content.replace(old_cart_item, new_cart_item)

with open('lib/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

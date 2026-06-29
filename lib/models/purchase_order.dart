class PurchaseOrderItem {
  final int? id;
  final int? productId;       // null for free-text items
  final String productName;
  final String unitPurchased; // e.g. Box, Strip, Tablet
  final double quantity;
  final double purchasePrice;
  final double sellingPrice;
  final double discount;
  final DateTime? expiryDate;

  const PurchaseOrderItem({
    this.id,
    this.productId,
    required this.productName,
    required this.unitPurchased,
    required this.quantity,
    required this.purchasePrice,
    this.sellingPrice = 0.0,
    this.discount = 0.0,
    this.expiryDate,
  });

  double get subtotal => quantity * purchasePrice - discount;

  PurchaseOrderItem copyWith({
    int? id,
    int? productId,
    String? productName,
    String? unitPurchased,
    double? quantity,
    double? purchasePrice,
    double? sellingPrice,
    double? discount,
    DateTime? expiryDate,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPurchased: unitPurchased ?? this.unitPurchased,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discount: discount ?? this.discount,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  static PurchaseOrderItem fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      unitPurchased: map['unit_purchased'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap(int orderId) => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'unit_purchased': unitPurchased,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'discount': discount,
        'expiry_date': expiryDate?.toIso8601String(),
      };
}

class PurchaseOrder {
  final int? id;
  final String poNumber;
  final String supplier;
  final DateTime orderDate;
  final List<PurchaseOrderItem> items;
  final String status;
  final String? notes;
  final double taxRate;
  final double paidAmount;

  const PurchaseOrder({
    this.id,
    required this.poNumber,
    required this.supplier,
    required this.orderDate,
    required this.items,
    required this.status,
    this.notes,
    this.taxRate = 0.0,
    this.paidAmount = 0.0,
  });

  double get subtotal    => items.fold(0, (s, i) => s + i.subtotal);
  double get taxAmount   => subtotal * taxRate / 100;
  double get totalAmount => subtotal + taxAmount;
  double get balanceDue  => totalAmount - paidAmount;

  PurchaseOrder copyWith({
    int? id,
    String? poNumber,
    String? supplier,
    DateTime? orderDate,
    List<PurchaseOrderItem>? items,
    String? status,
    String? notes,
    double? taxRate,
    double? paidAmount,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      supplier: supplier ?? this.supplier,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      taxRate: taxRate ?? this.taxRate,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  static PurchaseOrder fromMap(
      Map<String, dynamic> map, List<PurchaseOrderItem> items) {
    return PurchaseOrder(
      id: map['id'] as int?,
      poNumber: map['po_number'] as String,
      supplier: map['supplier'] as String,
      orderDate: DateTime.parse(map['order_date'] as String),
      items: items,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

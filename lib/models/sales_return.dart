class SalesReturnItem {
  int? id;
  int? salesReturnId;
  int productId;
  String productName;
  String unitName;
  double quantityReturned;
  double price;
  double total;

  SalesReturnItem({
    this.id,
    this.salesReturnId,
    required this.productId,
    required this.productName,
    this.unitName = 'Base Unit',
    required this.quantityReturned,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sales_return_id': salesReturnId,
      'product_id': productId,
      'product_name': productName,
      'unit_name': unitName,
      'quantity_returned': quantityReturned,
      'price': price,
      'total': total,
    };
  }

  factory SalesReturnItem.fromMap(Map<String, dynamic> map) {
    return SalesReturnItem(
      id: map['id'],
      salesReturnId: map['sales_return_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      unitName: map['unit_name']?.toString() ?? 'Base Unit',
      quantityReturned: map['quantity_returned'],
      price: map['price'],
      total: map['total'],
    );
  }
}

class SalesReturn {
  int? id;
  int dssId;
  DateTime date;
  String invoiceNumber;
  String? customerName;
  String mode; // 'Cash Refund', 'Store Credit', etc.
  String reason;
  double totalRefund;
  double cashRefunded;
  double creditIssued;
  String status; // 'Posted', 'Draft'
  List<SalesReturnItem> items;

  SalesReturn({
    this.id,
    required this.dssId,
    required this.date,
    required this.invoiceNumber,
    this.customerName,
    required this.mode,
    required this.reason,
    required this.totalRefund,
    required this.cashRefunded,
    required this.creditIssued,
    required this.status,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dss_id': dssId,
      'date': date.toIso8601String(),
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'mode': mode,
      'reason': reason,
      'total_refund': totalRefund,
      'cash_refunded': cashRefunded,
      'credit_issued': creditIssued,
      'status': status,
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    return SalesReturn(
      id: map['id'],
      dssId: map['dss_id'],
      date: DateTime.parse(map['date']),
      invoiceNumber: map['invoice_number'],
      customerName: map['customer_name'],
      mode: map['mode'],
      reason: map['reason'],
      totalRefund: map['total_refund'],
      cashRefunded: map['cash_refunded'],
      creditIssued: map['credit_issued'],
      status: map['status'],
    );
  }
}

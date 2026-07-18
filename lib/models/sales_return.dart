class SalesReturnItem {
  int? id;
  int? salesReturnId;
  int productId;
  String productName;
  String unitName;
  double quantityReturned;
  double price;
  double total;
  DateTime? expiryDate; // For batch matching on returns

  SalesReturnItem({
    this.id,
    this.salesReturnId,
    required this.productId,
    required this.productName,
    this.unitName = 'Base Unit',
    required this.quantityReturned,
    required this.price,
    required this.total,
    this.expiryDate,
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
      // expiryDate is NOT persisted to sales_return_items — it's only used
      // for batch look-up at the time of insertion.
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
      // expiryDate is transient — not stored in DB, only for batch matching
    );
  }
}

class SalesReturn {
  int? id;
  int dssId;
  DateTime date;
  String invoiceNumber;
  String returnNumber;
  String? customerName;
  String mode; // 'Cash Refund', 'Store Credit', etc.
  String reason;
  double totalRefund;
  double cashRefunded;
  double creditIssued;
  String status; // 'Posted', 'Draft'
  String? createdByUserId;
  String? createdByRole;
  List<SalesReturnItem> items;

  SalesReturn({
    this.id,
    required this.dssId,
    required this.date,
    required this.invoiceNumber,
    this.returnNumber = '',
    this.customerName,
    required this.mode,
    required this.reason,
    required this.totalRefund,
    required this.cashRefunded,
    required this.creditIssued,
    required this.status,
    this.createdByUserId,
    this.createdByRole,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dss_id': dssId,
      'date': date.toIso8601String(),
      'invoice_number': invoiceNumber,
      'return_number': returnNumber,
      'customer_name': customerName,
      'mode': mode,
      'reason': reason,
      'total_refund': totalRefund,
      'cash_refunded': cashRefunded,
      'credit_issued': creditIssued,
      'status': status,
      'created_by_user_id': createdByUserId,
      'created_by_role': createdByRole,
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    return SalesReturn(
      id: map['id'],
      dssId: map['dss_id'],
      date: DateTime.parse(map['date']),
      invoiceNumber: map['invoice_number'],
      returnNumber: map['return_number']?.toString() ?? '',
      customerName: map['customer_name'],
      mode: map['mode'],
      reason: map['reason'],
      totalRefund: map['total_refund'],
      cashRefunded: map['cash_refunded'],
      creditIssued: map['credit_issued'],
      status: map['status'],
      createdByUserId: map['created_by_user_user_id'] ?? map['created_by_user_id'], // fallback typo safeguard
      createdByRole: map['created_by_role'],
    );
  }
}

class Sale {
  final int? id;
  final int dssId;
  final String invoiceNumber;
  final String date;
  final String? customerId;
  final String? customerName;
  final double total;
  final double received;
  final double balance;
  final String paymentMethod;
  final String status;
  final double taxRate;
  final double taxAmount;
  final double discount;

  Sale({
    this.id,
    required this.dssId,
    required this.invoiceNumber,
    required this.date,
    this.customerId,
    this.customerName,
    required this.total,
    required this.received,
    required this.balance,
    required this.paymentMethod,
    required this.status,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dss_id': dssId,
      'invoice_number': invoiceNumber,
      'date': date,
      'customer_id': customerId,
      'customer_name': customerName,
      'total': total,
      'received': received,
      'balance': balance,
      'payment_method': paymentMethod,
      'status': status,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount': discount,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      dssId: map['dss_id'],
      invoiceNumber: map['invoice_number'],
      date: map['date'],
      customerId: map['customer_id']?.toString(),
      customerName: map['customer_name'],
      total: map['total'],
      received: map['received'],
      balance: map['balance'],
      paymentMethod: map['payment_method'],
      status: map['status'],
      taxRate: map['tax_rate'] ?? 0.0,
      taxAmount: map['tax_amount'] ?? 0.0,
      discount: map['discount'] ?? 0.0,
    );
  }
}

class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      price: map['price'],
      total: map['total'],
    );
  }
}

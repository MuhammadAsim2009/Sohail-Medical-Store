import 'dart:convert';

class CustomerPayment {
  final int? id;
  final String customerId;
  final String date;
  final double amount;
  final String reference;
  final String? invoiceNumber;
  final String notes;

  CustomerPayment({
    this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    required this.reference,
    this.invoiceNumber,
    this.notes = '',
  });

  CustomerPayment copyWith({
    int? id,
    String? customerId,
    String? date,
    double? amount,
    String? reference,
    String? invoiceNumber,
    String? notes,
  }) {
    return CustomerPayment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'date': date,
      'amount': amount,
      'reference': reference,
      'invoice_number': invoiceNumber,
      'notes': notes,
    };
  }

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id']?.toInt(),
      customerId: map['customer_id'] ?? '',
      date: map['date'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reference: map['reference'] ?? '',
      invoiceNumber: map['invoice_number']?.toString(),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomerPayment.fromJson(String source) => CustomerPayment.fromMap(json.decode(source));
}

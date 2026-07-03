import 'dart:convert';

class SupplierPayment {
  final int? id;
  final String supplierId;
  final String date;
  final double amount;
  final String reference;
  final String? invoiceNumber;
  final String notes;

  SupplierPayment({
    this.id,
    required this.supplierId,
    required this.date,
    required this.amount,
    required this.reference,
    this.invoiceNumber,
    this.notes = '',
  });

  SupplierPayment copyWith({
    int? id,
    String? supplierId,
    String? date,
    double? amount,
    String? reference,
    String? invoiceNumber,
    String? notes,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
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
      'supplier_id': supplierId,
      'date': date,
      'amount': amount,
      'reference': reference,
      'invoice_number': invoiceNumber,
      'notes': notes,
    };
  }

  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id']?.toInt(),
      supplierId: map['supplier_id'] ?? '',
      date: map['date'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reference: map['reference'] ?? '',
      invoiceNumber: map['invoice_number']?.toString(),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SupplierPayment.fromJson(String source) => SupplierPayment.fromMap(json.decode(source));
}

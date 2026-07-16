import 'dart:convert';

class Supplier {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final List<String> categoriesSupplied;
  final DateTime lastOrderDate;
  final double pendingAmount;
  final double advanceAmount;

  Supplier({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.categoriesSupplied,
    required this.lastOrderDate,
    this.pendingAmount = 0.0,
    this.advanceAmount = 0.0,
  });

  Supplier copyWith({
    String? id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    List<String>? categoriesSupplied,
    DateTime? lastOrderDate,
    double? pendingAmount,
    double? advanceAmount,
  }) {
    return Supplier(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      categoriesSupplied: categoriesSupplied ?? this.categoriesSupplied,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'categoriesSupplied': jsonEncode(categoriesSupplied),
      'lastOrderDate': lastOrderDate.toIso8601String(),
      'pendingAmount': pendingAmount,
      'advanceAmount': advanceAmount,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      contactPerson: map['contactPerson']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      categoriesSupplied: map['categoriesSupplied'] != null
          ? List<String>.from(jsonDecode(map['categoriesSupplied']))
          : [],
      lastOrderDate: map['lastOrderDate'] != null
          ? DateTime.parse(map['lastOrderDate'])
          : DateTime.now(),
      pendingAmount: (map['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (map['advanceAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

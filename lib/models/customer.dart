import 'dart:convert';

class Customer {
  final String? id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double totalPurchases;
  final double pendingAmount;
  final double advanceAmount;
  final DateTime lastVisit;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalPurchases = 0.0,
    this.pendingAmount = 0.0,
    this.advanceAmount = 0.0,
    required this.lastVisit,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalPurchases,
    double? pendingAmount,
    double? advanceAmount,
    DateTime? lastVisit,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalPurchases': totalPurchases,
      'pendingAmount': pendingAmount,
      'advanceAmount': advanceAmount,
      'lastVisit': lastVisit.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      totalPurchases: (map['totalPurchases'] ?? 0).toDouble(),
      pendingAmount: (map['pendingAmount'] ?? 0).toDouble(),
      advanceAmount: (map['advanceAmount'] ?? 0).toDouble(),
      lastVisit: map['lastVisit'] != null ? DateTime.parse(map['lastVisit']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));
}

import 'dart:convert';

class Expense {
  final int? id;
  final String date;
  final String category;
  final String title;
  final double amount;
  final String notes;

  Expense({
    this.id,
    required this.date,
    required this.category,
    required this.title,
    required this.amount,
    this.notes = '',
  });

  Expense copyWith({
    int? id,
    String? date,
    String? category,
    String? title,
    double? amount,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'category': category,
      'title': title,
      'amount': amount,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toInt(),
      date: map['date'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String source) => Expense.fromMap(json.decode(source));
}

class DailySalesSheet {
  final int? id;
  final String date;
  final double openingBalance;
  final double expectedCash;
  final double actualCash;
  final String status;

  DailySalesSheet({
    this.id,
    required this.date,
    required this.openingBalance,
    required this.expectedCash,
    required this.actualCash,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'opening_balance': openingBalance,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'status': status,
    };
  }

  factory DailySalesSheet.fromMap(Map<String, dynamic> map) {
    return DailySalesSheet(
      id: map['id'],
      date: map['date'],
      openingBalance: map['opening_balance'],
      expectedCash: map['expected_cash'],
      actualCash: map['actual_cash'],
      status: map['status'],
    );
  }
}

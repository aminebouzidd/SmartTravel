class BudgetExpense {
  final String id;
  final double amount;
  final String currency;
  final String label;
  final DateTime timestamp;

  const BudgetExpense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.label,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'label': label,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BudgetExpense.fromJson(Map<String, dynamic> json) => BudgetExpense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String,
    label: json['label'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

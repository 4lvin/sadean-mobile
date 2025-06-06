// lib/src/models/income_expense_model.dart

class IncomeExpense {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  IncomeExpense({
    required this.id,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory IncomeExpense.fromJson(Map<String, dynamic> json) {
    return IncomeExpense(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'cash',
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  IncomeExpense copyWith({
    String? id,
    String? type,
    double? amount,
    String? paymentMethod,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeExpense(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
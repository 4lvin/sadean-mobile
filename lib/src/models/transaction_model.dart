class Transaction {
  final String id;
  final DateTime date;
  final List<TransactionItem> items;
  final double totalAmount;
  final double costAmount;
  final double profit;

  Transaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.costAmount,
    required this.profit,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'costAmount': costAmount,
    'profit': profit,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    date: DateTime.parse(json['date']),
    items: (json['items'] as List).map((item) => TransactionItem.fromJson(item)).toList(),
    totalAmount: json['totalAmount'],
    costAmount: json['costAmount'],
    profit: json['profit'],
  );
}

class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double costPrice;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'costPrice': costPrice,
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    unitPrice: json['unitPrice'],
    costPrice: json['costPrice'],
  );
}
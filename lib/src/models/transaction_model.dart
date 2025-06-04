class Transaction {
  final String id;
  final DateTime date;
  final List<TransactionItem> items;
  final double totalAmount;
  final double costAmount;
  final double profit;

  // Transaction adjustments
  final double? subtotal;
  final double? discount;
  final double? tax;
  final double? shippingCost;
  final double? serviceFee;

  // Payment information
  final String paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final String paymentStatus;

  final String? customerName;
  final String? notes;

  Transaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.costAmount,
    required this.profit,
    this.subtotal,
    this.discount,
    this.tax,
    this.shippingCost,
    this.serviceFee,
    this.paymentMethod = 'cash',
    this.amountPaid = 0,
    this.changeAmount = 0,
    this.paymentStatus = 'paid',
    this.customerName,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'total_amount': totalAmount,
    'cost_amount': costAmount,
    'profit': profit,
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'shipping_cost': shippingCost,
    'service_fee': serviceFee,
    'payment_method': paymentMethod,
    'amount_paid': amountPaid,
    'change_amount': changeAmount,
    'payment_status': paymentStatus,
    'customer_name': customerName,
    'notes': notes,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    date: DateTime.parse(json['date']),
    items: (json['items'] as List).map((item) => TransactionItem.fromJson(item)).toList(),
    totalAmount: json['total_amount']?.toDouble() ?? 0.0,
    costAmount: json['cost_amount']?.toDouble() ?? 0.0,
    profit: json['profit']?.toDouble() ?? 0.0,
    subtotal: json['subtotal']?.toDouble(),
    discount: json['discount']?.toDouble(),
    tax: json['tax']?.toDouble(),
    shippingCost: json['shipping_cost']?.toDouble(),
    serviceFee: json['service_fee']?.toDouble(),
    paymentMethod: json['payment_method'] ?? 'cash',
    amountPaid: json['amount_paid']?.toDouble() ?? 0.0,
    changeAmount: json['change_amount']?.toDouble() ?? 0.0,
    paymentStatus: json['payment_status'] ?? 'paid',
    customerName: json['customer_name'],
    notes: json['notes'],
  );

  // Helper method to get formatted breakdown
  Map<String, double> getBreakdown() {
    final breakdown = <String, double>{};

    if (subtotal != null) breakdown['Subtotal'] = subtotal!;
    if (discount != null && discount! > 0) breakdown['Diskon'] = -discount!;
    if (serviceFee != null && serviceFee! > 0) breakdown['Biaya Layanan'] = serviceFee!;
    if (shippingCost != null && shippingCost! > 0) breakdown['Biaya Pengiriman'] = shippingCost!;
    if (tax != null && tax! > 0) breakdown['Pajak'] = tax!;
    breakdown['Total'] = totalAmount;

    return breakdown;
  }

  // Helper method to check if transaction has adjustments
  bool get hasAdjustments {
    return (discount != null && discount! > 0) ||
        (tax != null && tax! > 0) ||
        (shippingCost != null && shippingCost! > 0) ||
        (serviceFee != null && serviceFee! > 0);
  }

  // Calculate actual subtotal if not stored
  double get calculatedSubtotal {
    return subtotal ?? items.fold<double>(0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  // Helper methods for payment
  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isCancelled => paymentStatus == 'cancelled';

  Transaction copyWith({
    String? id,
    DateTime? date,
    List<TransactionItem>? items,
    double? totalAmount,
    double? costAmount,
    double? profit,
    double? subtotal,
    double? discount,
    double? tax,
    double? shippingCost,
    double? serviceFee,
    String? paymentMethod,
    double? amountPaid,
    double? changeAmount,
    String? paymentStatus,
    String? customerName,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      costAmount: costAmount ?? this.costAmount,
      profit: profit ?? this.profit,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      shippingCost: shippingCost ?? this.shippingCost,
      serviceFee: serviceFee ?? this.serviceFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }
}

class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double costPrice;

  TransactionItem ({
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
    unitPrice: json['unitPrice']?.toDouble() ?? 0.0,
    costPrice: json['costPrice']?.toDouble() ?? 0.0,
  );

  // Calculate total for this item
  double get totalPrice => quantity * unitPrice;
  double get totalCost => quantity * costPrice;
  double get itemProfit => totalPrice - totalCost;

  TransactionItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? costPrice,
  }) {
    return TransactionItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
    );
  }
}
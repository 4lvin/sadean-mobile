// lib/src/models/customer_model.dart

class Customer {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? barcode;
  final String? address;
  final double balance; // Total transaksi - Total pembayaran
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.barcode,
    this.address,
    this.balance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
    'email': email,
    'barcode': barcode,
    'address': address,
    'balance': balance,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'],
    name: json['name'],
    phoneNumber: json['phone_number'],
    email: json['email'],
    barcode: json['barcode'],
    address: json['address'],
    balance: (json['balance'] ?? 0).toDouble(),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Customer copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? barcode,
    String? address,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      barcode: barcode ?? this.barcode,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get hasBalance => balance > 0;
  bool get isBalancePaid => balance <= 0;
  String get displayName => name;
  String get displayPhone => phoneNumber ?? '-';
  String get displayEmail => email ?? '-';
}

// Customer Transaction Model
class CustomerTransaction {
  final String id;
  final String customerId;
  final String type; // 'invoice' atau 'payment'
  final double amount;
  final String? paymentMethod;
  final String? notes;
  final String status; // 'paid' atau 'pending'
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.paymentMethod,
    this.notes,
    this.status = 'pending',
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'type': type,
    'amount': amount,
    'payment_method': paymentMethod,
    'notes': notes,
    'status': status,
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) => CustomerTransaction(
    id: json['id'],
    customerId: json['customer_id'],
    type: json['type'],
    amount: (json['amount'] ?? 0).toDouble(),
    paymentMethod: json['payment_method'],
    notes: json['notes'],
    status: json['status'] ?? 'pending',
    date: DateTime.parse(json['date']),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  bool get isInvoice => type == 'invoice';
  bool get isPayment => type == 'payment';
  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
}
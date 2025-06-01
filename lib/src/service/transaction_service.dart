import 'package:get/get.dart';
import 'package:sadean/src/service/product_service.dart';
import 'package:sadean/src/service/secure_storage_service.dart';

import '../models/transaction_model.dart';

class TransactionService extends GetxService {
  final SecureStorageService _storage = Get.find<SecureStorageService>();
  final ProductService _productService = Get.find<ProductService>();
  static const String _storageKey = 'transactions';

  Future<List<Transaction>> getAllTransactions() async {
    try {
      final List<Map<String, dynamic>> data = await _storage.getList(_storageKey);
      return data.map((item) => Transaction.fromJson(item)).toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<Transaction> addTransaction({
    required List<TransactionItem> items,
    double discount = 0,
    double tax = 0,
  }) async {
    if (items.isEmpty) {
      throw Exception('Transaksi harus memiliki minimal 1 item');
    }

    // Validate stock availability
    for (final item in items) {
      final product = (await _productService.getAllProducts())
          .firstWhere((p) => p.id == item.productId);

      if (product.stock < item.quantity) {
        throw Exception('Stok ${product.name} tidak mencukupi');
      }
    }

    final transactions = await getAllTransactions();

    // Calculate totals
    final subtotal = items.fold<double>(
      0,
          (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final costAmount = items.fold<double>(
      0,
          (sum, item) => sum + (item.quantity * item.costPrice),
    );
    final totalAmount = subtotal - discount + tax;
    final profit = totalAmount - costAmount;

    final newTransaction = Transaction(
      id: _generateTransactionId(),
      date: DateTime.now(),
      items: items,
      totalAmount: totalAmount,
      costAmount: costAmount,
      profit: profit,
    );

    transactions.insert(0, newTransaction); // Add to beginning for recent first
    await _saveAllTransactions(transactions);

    // Update product stock and sold count
    for (final item in items) {
      await _productService.updateSoldCount(item.productId, item.quantity);
    }

    return newTransaction;
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = await getAllTransactions();
    final transactionIndex = transactions.indexWhere((t) => t.id == id);

    if (transactionIndex == -1) {
      throw Exception('Transaksi tidak ditemukan');
    }

    final transaction = transactions[transactionIndex];

    // Restore stock for deleted transaction
    for (final item in transaction.items) {
      await _productService.updateSoldCount(item.productId, -item.quantity);
    }

    transactions.removeAt(transactionIndex);
    await _saveAllTransactions(transactions);
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final transactions = await getAllTransactions();
    return transactions.where((transaction) {
      return transaction.date.isAfter(startDate) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Future<List<Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  Future<Map<String, double>> getDashboardStats() async {
    final transactions = await getAllTransactions();

    final totalRevenue = transactions.fold<double>(
      0,
          (sum, transaction) => sum + transaction.totalAmount,
    );

    final totalCost = transactions.fold<double>(
      0,
          (sum, transaction) => sum + transaction.costAmount,
    );

    final totalProfit = transactions.fold<double>(
      0,
          (sum, transaction) => sum + transaction.profit,
    );

    return {
      'revenue': totalRevenue,
      'cost': totalCost,
      'profit': totalProfit,
      'transactionCount': transactions.length.toDouble(),
    };
  }

  String _generateTransactionId() {
    final now = DateTime.now();
    final dateString = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeString = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'TRX$dateString$timeString';
  }

  Future<void> _saveAllTransactions(List<Transaction> transactions) async {
    final data = transactions.map((transaction) => transaction.toJson()).toList();
    await _storage.saveList(_storageKey, data);
  }
}

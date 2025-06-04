import 'package:get/get.dart';
import '../models/transaction_model.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'database_helper.dart';
import 'product_service.dart';

class TransactionService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ProductService _productService = Get.find<ProductService>();

  Future<List<Transaction>> getAllTransactions() async {
    try {
      final List<Map<String, dynamic>> transactionMaps = await _dbHelper.query(
        DatabaseHelper.tableTransactions,
        orderBy: 'date DESC',
      );

      List<Transaction> transactions = [];

      for (final transactionMap in transactionMaps) {
        final items = await _getTransactionItems(transactionMap['id']);
        transactions.add(Transaction(
          id: transactionMap['id'],
          date: DateTime.parse(transactionMap['date']),
          items: items,
          totalAmount: transactionMap['total_amount']?.toDouble() ?? 0.0,
          costAmount: transactionMap['cost_amount']?.toDouble() ?? 0.0,
          profit: transactionMap['profit']?.toDouble() ?? 0.0,
          subtotal: transactionMap['subtotal']?.toDouble(),
          discount: transactionMap['discount']?.toDouble(),
          tax: transactionMap['tax']?.toDouble(),
          shippingCost: transactionMap['shipping_cost']?.toDouble(),
          serviceFee: transactionMap['service_fee']?.toDouble(),
          paymentMethod: transactionMap['payment_method'] ?? 'cash',
          amountPaid: transactionMap['amount_paid']?.toDouble() ?? 0.0,
          changeAmount: transactionMap['change_amount']?.toDouble() ?? 0.0,
          paymentStatus: transactionMap['payment_status'] ?? 'paid',
          customerName: transactionMap['customer_name'],
          notes: transactionMap['notes'],
        ));
      }

      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<Transaction?> getTransactionById(String id) async {
    try {
      final List<Map<String, dynamic>> transactionMaps = await _dbHelper.query(
        DatabaseHelper.tableTransactions,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (transactionMaps.isEmpty) return null;

      final transactionMap = transactionMaps.first;
      final items = await _getTransactionItems(id);

      return Transaction(
        id: transactionMap['id'],
        date: DateTime.parse(transactionMap['date']),
        items: items,
        totalAmount: transactionMap['total_amount']?.toDouble() ?? 0.0,
        costAmount: transactionMap['cost_amount']?.toDouble() ?? 0.0,
        profit: transactionMap['profit']?.toDouble() ?? 0.0,
        subtotal: transactionMap['subtotal']?.toDouble(),
        discount: transactionMap['discount']?.toDouble(),
        tax: transactionMap['tax']?.toDouble(),
        shippingCost: transactionMap['shipping_cost']?.toDouble(),
        serviceFee: transactionMap['service_fee']?.toDouble(),
        paymentMethod: transactionMap['payment_method'] ?? 'cash',
        amountPaid: transactionMap['amount_paid']?.toDouble() ?? 0.0,
        changeAmount: transactionMap['change_amount']?.toDouble() ?? 0.0,
        paymentStatus: transactionMap['payment_status'] ?? 'paid',
        customerName: transactionMap['customer_name'],
        notes: transactionMap['notes'],
      );
    } catch (e) {
      print('Error getting transaction by id: $e');
      return null;
    }
  }

  Future<Transaction> addTransaction({
    required List<TransactionItem> items,
    double discount = 0,
    double tax = 0,
    double shippingCost = 0,
    double serviceFee = 0,
    String paymentMethod = 'cash',
    double amountPaid = 0,
    double changeAmount = 0,
    String paymentStatus = 'paid',
    String? customerName,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw Exception('Transaksi harus memiliki minimal 1 item');
    }

    try {
      return await _dbHelper.transaction((txn) async {
        // Validate stock availability
        for (final item in items) {
          final productResult = await txn.query(
            DatabaseHelper.tableProducts,
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (productResult.isEmpty) {
            throw Exception('Produk ${item.productName} tidak ditemukan');
          }

          final product = productResult.first;
          if (product['stock'] as int < item.quantity) {
            throw Exception('Stok ${product['name']} tidak mencukupi');
          }
        }

        // Calculate totals
        final subtotal = items.fold<double>(
          0,
              (sum, item) => sum + (item.quantity * item.unitPrice),
        );
        final costAmount = items.fold<double>(
          0,
              (sum, item) => sum + (item.quantity * item.costPrice),
        );
        final totalAmount = subtotal - discount + tax + shippingCost + serviceFee;
        final profit = totalAmount - costAmount;

        final transactionId = _generateTransactionId();
        final now = DateTime.now();

        // Insert transaction with payment information
        await txn.insert(DatabaseHelper.tableTransactions, {
          'id': transactionId,
          'date': now.toIso8601String(),
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
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        // Insert transaction items and update product stock
        for (final item in items) {
          // Insert transaction item
          await txn.insert(DatabaseHelper.tableTransactionItems, {
            'transaction_id': transactionId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'cost_price': item.costPrice,
          });

          // Update product stock and sold count
          final productResult = await txn.query(
            DatabaseHelper.tableProducts,
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          final product = productResult.first;
          final newStock = (product['stock'] as int) - item.quantity;
          final newSoldCount = (product['sold_count'] as int) + item.quantity;

          await txn.update(
            DatabaseHelper.tableProducts,
            {
              'stock': newStock,
              'sold_count': newSoldCount,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          // Update category sold count
          await _updateCategorySoldCount(product['category_id'] as String, txn);
        }

        return Transaction(
          id: transactionId,
          date: now,
          items: items,
          totalAmount: totalAmount,
          costAmount: costAmount,
          profit: profit,
          subtotal: subtotal,
          discount: discount,
          tax: tax,
          shippingCost: shippingCost,
          serviceFee: serviceFee,
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          changeAmount: changeAmount,
          paymentStatus: paymentStatus,
          customerName: customerName,
          notes: notes,
        );
      });
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransactionPayment({
    required String transactionId,
    required String paymentMethod,
    required double amountPaid,
    required double changeAmount,
    required String paymentStatus,
  }) async {
    try {
      await _dbHelper.update(
        DatabaseHelper.tableTransactions,
        {
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
          'change_amount': changeAmount,
          'payment_status': paymentStatus,
        },
        'id = ?',
        [transactionId],
      );
    } catch (e) {
      print('Error updating transaction payment: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dbHelper.transaction((txn) async {
        // Get transaction items to restore stock
        final items = await _getTransactionItems(id);

        if (items.isEmpty) {
          throw Exception('Transaksi tidak ditemukan');
        }

        // Restore product stock and sold count
        for (final item in items) {
          final productResult = await txn.query(
            DatabaseHelper.tableProducts,
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (productResult.isNotEmpty) {
            final product = productResult.first;
            final newStock = (product['stock'] as int) + item.quantity;
            final newSoldCount = (product['sold_count'] as int) - item.quantity;

            await txn.update(
              DatabaseHelper.tableProducts,
              {
                'stock': newStock,
                'sold_count': newSoldCount.clamp(0, double.infinity).toInt(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [item.productId],
            );

            // Update category sold count
            await _updateCategorySoldCount(product['category_id'] as String, txn);
          }
        }

        // Delete transaction items first (foreign key constraint)
        await txn.delete(
          DatabaseHelper.tableTransactionItems,
          where: 'transaction_id = ?',
          whereArgs: [id],
        );

        // Delete transaction
        await txn.delete(
          DatabaseHelper.tableTransactions,
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final List<Map<String, dynamic>> transactionMaps = await _dbHelper.query(
        DatabaseHelper.tableTransactions,
        where: 'date >= ? AND date <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.add(const Duration(days: 1)).toIso8601String(),
        ],
        orderBy: 'date DESC',
      );

      List<Transaction> transactions = [];

      for (final transactionMap in transactionMaps) {
        final items = await _getTransactionItems(transactionMap['id']);
        transactions.add(Transaction(
          id: transactionMap['id'],
          date: DateTime.parse(transactionMap['date']),
          items: items,
          totalAmount: transactionMap['total_amount']?.toDouble() ?? 0.0,
          costAmount: transactionMap['cost_amount']?.toDouble() ?? 0.0,
          profit: transactionMap['profit']?.toDouble() ?? 0.0,
          subtotal: transactionMap['subtotal']?.toDouble(),
          discount: transactionMap['discount']?.toDouble(),
          tax: transactionMap['tax']?.toDouble(),
          shippingCost: transactionMap['shipping_cost']?.toDouble(),
          serviceFee: transactionMap['service_fee']?.toDouble(),
          paymentMethod: transactionMap['payment_method'] ?? 'cash',
          amountPaid: transactionMap['amount_paid']?.toDouble() ?? 0.0,
          changeAmount: transactionMap['change_amount']?.toDouble() ?? 0.0,
          paymentStatus: transactionMap['payment_status'] ?? 'paid',
          customerName: transactionMap['customer_name'],
          notes: transactionMap['notes'],
        ));
      }

      return transactions;
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  Future<List<Transaction>> getTransactionsByPaymentMethod(String paymentMethod) async {
    try {
      final List<Map<String, dynamic>> transactionMaps = await _dbHelper.query(
        DatabaseHelper.tableTransactions,
        where: 'payment_method = ?',
        whereArgs: [paymentMethod],
        orderBy: 'date DESC',
      );

      List<Transaction> transactions = [];

      for (final transactionMap in transactionMaps) {
        final items = await _getTransactionItems(transactionMap['id']);
        transactions.add(Transaction(
          id: transactionMap['id'],
          date: DateTime.parse(transactionMap['date']),
          items: items,
          totalAmount: transactionMap['total_amount']?.toDouble() ?? 0.0,
          costAmount: transactionMap['cost_amount']?.toDouble() ?? 0.0,
          profit: transactionMap['profit']?.toDouble() ?? 0.0,
          subtotal: transactionMap['subtotal']?.toDouble(),
          discount: transactionMap['discount']?.toDouble(),
          tax: transactionMap['tax']?.toDouble(),
          shippingCost: transactionMap['shipping_cost']?.toDouble(),
          serviceFee: transactionMap['service_fee']?.toDouble(),
          paymentMethod: transactionMap['payment_method'] ?? 'cash',
          amountPaid: transactionMap['amount_paid']?.toDouble() ?? 0.0,
          changeAmount: transactionMap['change_amount']?.toDouble() ?? 0.0,
          paymentStatus: transactionMap['payment_status'] ?? 'paid',
          customerName: transactionMap['customer_name'],
          notes: transactionMap['notes'],
        ));
      }

      return transactions;
    } catch (e) {
      print('Error getting transactions by payment method: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByStatus(String status) async {
    try {
      final List<Map<String, dynamic>> transactionMaps = await _dbHelper.query(
        DatabaseHelper.tableTransactions,
        where: 'payment_status = ?',
        whereArgs: [status],
        orderBy: 'date DESC',
      );

      List<Transaction> transactions = [];

      for (final transactionMap in transactionMaps) {
        final items = await _getTransactionItems(transactionMap['id']);
        transactions.add(Transaction(
          id: transactionMap['id'],
          date: DateTime.parse(transactionMap['date']),
          items: items,
          totalAmount: transactionMap['total_amount']?.toDouble() ?? 0.0,
          costAmount: transactionMap['cost_amount']?.toDouble() ?? 0.0,
          profit: transactionMap['profit']?.toDouble() ?? 0.0,
          subtotal: transactionMap['subtotal']?.toDouble(),
          discount: transactionMap['discount']?.toDouble(),
          tax: transactionMap['tax']?.toDouble(),
          shippingCost: transactionMap['shipping_cost']?.toDouble(),
          serviceFee: transactionMap['service_fee']?.toDouble(),
          paymentMethod: transactionMap['payment_method'] ?? 'cash',
          amountPaid: transactionMap['amount_paid']?.toDouble() ?? 0.0,
          changeAmount: transactionMap['change_amount']?.toDouble() ?? 0.0,
          paymentStatus: transactionMap['payment_status'] ?? 'paid',
          customerName: transactionMap['customer_name'],
          notes: transactionMap['notes'],
        ));
      }

      return transactions;
    } catch (e) {
      print('Error getting transactions by status: $e');
      return [];
    }
  }

  Future<Map<String, double>> getDashboardStats() async {
    try {
      final result = await _dbHelper.rawQuery('''
        SELECT 
          COUNT(*) as transaction_count,
          COALESCE(SUM(total_amount), 0) as total_revenue,
          COALESCE(SUM(cost_amount), 0) as total_cost,
          COALESCE(SUM(profit), 0) as total_profit,
          COALESCE(SUM(amount_paid), 0) as total_paid,
          COALESCE(SUM(change_amount), 0) as total_change
        FROM ${DatabaseHelper.tableTransactions}
        WHERE payment_status = 'paid'
      ''');

      final stats = result.first;
      return {
        'revenue': stats['total_revenue'] as double,
        'cost': stats['total_cost'] as double,
        'profit': stats['total_profit'] as double,
        'transactionCount': (stats['transaction_count'] as int).toDouble(),
        'totalPaid': stats['total_paid'] as double,
        'totalChange': stats['total_change'] as double,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'revenue': 0.0,
        'cost': 0.0,
        'profit': 0.0,
        'transactionCount': 0.0,
        'totalPaid': 0.0,
        'totalChange': 0.0,
      };
    }
  }

  Future<Map<String, double>> getTodayStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _dbHelper.rawQuery('''
        SELECT 
          COUNT(*) as transaction_count,
          COALESCE(SUM(total_amount), 0) as total_revenue,
          COALESCE(SUM(cost_amount), 0) as total_cost,
          COALESCE(SUM(profit), 0) as total_profit,
          COALESCE(SUM(amount_paid), 0) as total_paid,
          COALESCE(SUM(change_amount), 0) as total_change
        FROM ${DatabaseHelper.tableTransactions}
        WHERE date >= ? AND date < ? AND payment_status = 'paid'
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      final stats = result.first;
      return {
        'revenue': stats['total_revenue'] as double,
        'cost': stats['total_cost'] as double,
        'profit': stats['total_profit'] as double,
        'transactionCount': (stats['transaction_count'] as int).toDouble(),
        'totalPaid': stats['total_paid'] as double,
        'totalChange': stats['total_change'] as double,
      };
    } catch (e) {
      print('Error getting today stats: $e');
      return {
        'revenue': 0.0,
        'cost': 0.0,
        'profit': 0.0,
        'transactionCount': 0.0,
        'totalPaid': 0.0,
        'totalChange': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> getPaymentMethodStats() async {
    try {
      final result = await _dbHelper.rawQuery('''
        SELECT 
          payment_method,
          COUNT(*) as transaction_count,
          COALESCE(SUM(total_amount), 0) as total_amount
        FROM ${DatabaseHelper.tableTransactions}
        WHERE payment_status = 'paid'
        GROUP BY payment_method
        ORDER BY total_amount DESC
      ''');

      return {
        'byMethod': result,
        'totalMethods': result.length,
      };
    } catch (e) {
      print('Error getting payment method stats: $e');
      return {
        'byMethod': [],
        'totalMethods': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats({int months = 12}) async {
    try {
      final result = await _dbHelper.rawQuery('''
        SELECT 
          strftime('%Y-%m', date) as month,
          COUNT(*) as transaction_count,
          COALESCE(SUM(total_amount), 0) as total_revenue,
          COALESCE(SUM(cost_amount), 0) as total_cost,
          COALESCE(SUM(profit), 0) as total_profit,
          COALESCE(SUM(amount_paid), 0) as total_paid,
          COALESCE(SUM(change_amount), 0) as total_change
        FROM ${DatabaseHelper.tableTransactions}
        WHERE date >= datetime('now', '-$months months') AND payment_status = 'paid'
        GROUP BY strftime('%Y-%m', date)
        ORDER BY month DESC
      ''');

      return result;
    } catch (e) {
      print('Error getting monthly stats: $e');
      return [];
    }
  }

  // New method to get payment summary
  Future<Map<String, dynamic>> getPaymentSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = "payment_status = 'paid'";
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        whereClause += " AND date >= ? AND date <= ?";
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.add(const Duration(days: 1)).toIso8601String(),
        ]);
      }

      final result = await _dbHelper.rawQuery('''
        SELECT 
          payment_method,
          COUNT(*) as transaction_count,
          COALESCE(SUM(total_amount), 0) as total_amount,
          COALESCE(SUM(amount_paid), 0) as total_paid,
          COALESCE(SUM(change_amount), 0) as total_change
        FROM ${DatabaseHelper.tableTransactions}
        WHERE $whereClause
        GROUP BY payment_method
        ORDER BY total_amount DESC
      ''', whereArgs);

      final totalResult = await _dbHelper.rawQuery('''
        SELECT 
          COUNT(*) as total_transactions,
          COALESCE(SUM(total_amount), 0) as total_revenue,
          COALESCE(SUM(amount_paid), 0) as total_paid,
          COALESCE(SUM(change_amount), 0) as total_change
        FROM ${DatabaseHelper.tableTransactions}
        WHERE $whereClause
      ''', whereArgs);

      return {
        'byMethod': result,
        'summary': totalResult.isNotEmpty ? totalResult.first : {},
      };
    } catch (e) {
      print('Error getting payment summary: $e');
      return {
        'byMethod': [],
        'summary': {},
      };
    }
  }

  // New method to update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
  }) async {
    try {
      await _dbHelper.update(
        DatabaseHelper.tableTransactions,
        {'payment_status': status},
        'id = ?',
        [transactionId],
      );
    } catch (e) {
      print('Error updating transaction status: $e');
      rethrow;
    }
  }

  // New method to get pending transactions
  Future<List<Transaction>> getPendingTransactions() async {
    return getTransactionsByStatus('pending');
  }

  // New method to get completed transactions
  Future<List<Transaction>> getCompletedTransactions() async {
    return getTransactionsByStatus('paid');
  }

  // New method to get cancelled transactions
  Future<List<Transaction>> getCancelledTransactions() async {
    return getTransactionsByStatus('cancelled');
  }

  // Helper methods
  Future<List<TransactionItem>> _getTransactionItems(String transactionId) async {
    try {
      final List<Map<String, dynamic>> itemMaps = await _dbHelper.query(
        DatabaseHelper.tableTransactionItems,
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      return itemMaps.map((map) => TransactionItem(
        productId: map['product_id'],
        productName: map['product_name'],
        quantity: map['quantity'],
        unitPrice: map['unit_price']?.toDouble() ?? 0.0,
        costPrice: map['cost_price']?.toDouble() ?? 0.0,
      )).toList();
    } catch (e) {
      print('Error getting transaction items: $e');
      return [];
    }
  }

  Future<void> _updateCategorySoldCount(String categoryId, sql.Transaction txn) async {
    try {
      final soldResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(sold_count), 0) as total_sold FROM ${DatabaseHelper.tableProducts} WHERE category_id = ?',
        [categoryId],
      );

      final totalSold = soldResult.first['total_sold'] as int;

      await txn.update(
        DatabaseHelper.tableCategories,
        {
          'sold_count': totalSold,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    } catch (e) {
      print('Error updating category sold count: $e');
    }
  }

  String _generateTransactionId() {
    final now = DateTime.now();
    final dateString = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeString = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'TRX$dateString$timeString';
  }
}
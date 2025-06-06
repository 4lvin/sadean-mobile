// lib/src/service/income_expense_service.dart

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/income_expense_model.dart';
import 'database_helper.dart';

class IncomeExpenseService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all records
  Future<List<IncomeExpense>> getAllRecords() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableIncomeExpense,
        orderBy: 'date DESC',
      );

      return maps.map((map) => IncomeExpense.fromJson(map)).toList();
    } catch (e) {
      print('Error getting all records: $e');
      return [];
    }
  }

  // Get records by type
  Future<List<IncomeExpense>> getRecordsByType(String type) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableIncomeExpense,
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'date DESC',
      );

      return maps.map((map) => IncomeExpense.fromJson(map)).toList();
    } catch (e) {
      print('Error getting records by type: $e');
      return [];
    }
  }

  // Get all income records
  Future<List<IncomeExpense>> getAllIncome() async {
    return getRecordsByType('income');
  }

  // Get all expense records
  Future<List<IncomeExpense>> getAllExpenses() async {
    return getRecordsByType('expense');
  }

  // Get record by ID
  Future<IncomeExpense?> getRecordById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableIncomeExpense,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return IncomeExpense.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting record by id: $e');
      return null;
    }
  }

  // Add new record
  Future<IncomeExpense> addRecord({
    required String type,
    required double amount,
    required String paymentMethod,
    String? notes,
    required DateTime date,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Jumlah harus lebih dari 0');
      }

      final now = DateTime.now();
      final newRecord = IncomeExpense(
        id: const Uuid().v4(),
        type: type,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
        date: date,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insert(
        DatabaseHelper.tableIncomeExpense,
        newRecord.toJson(),
      );

      return newRecord;
    } catch (e) {
      print('Error adding record: $e');
      rethrow;
    }
  }

  // Update record
  Future<void> updateRecord({
    required String id,
    required double amount,
    required String paymentMethod,
    String? notes,
    required DateTime date,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Jumlah harus lebih dari 0');
      }

      await _dbHelper.update(
        DatabaseHelper.tableIncomeExpense,
        {
          'amount': amount,
          'payment_method': paymentMethod,
          'notes': notes,
          'date': date.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [id],
      );
    } catch (e) {
      print('Error updating record: $e');
      rethrow;
    }
  }

  // Delete record
  Future<void> deleteRecord(String id) async {
    try {
      await _dbHelper.delete(
        DatabaseHelper.tableIncomeExpense,
        'id = ?',
        [id],
      );
    } catch (e) {
      print('Error deleting record: $e');
      rethrow;
    }
  }

  // Get records by date range
  Future<List<IncomeExpense>> getRecordsByDateRange(
      DateTime startDate,
      DateTime endDate, {
        String? type,
      }) async {
    try {
      String whereClause = 'date >= ? AND date <= ?';
      List<dynamic> whereArgs = [
        startDate.toIso8601String(),
        endDate.add(const Duration(days: 1)).toIso8601String(),
      ];

      if (type != null) {
        whereClause += ' AND type = ?';
        whereArgs.add(type);
      }

      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableIncomeExpense,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'date DESC',
      );

      return maps.map((map) => IncomeExpense.fromJson(map)).toList();
    } catch (e) {
      print('Error getting records by date range: $e');
      return [];
    }
  }

  // Get today's records
  Future<List<IncomeExpense>> getTodayRecords({String? type}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getRecordsByDateRange(startOfDay, endOfDay, type: type);
  }

  // Get monthly records
  Future<List<IncomeExpense>> getMonthlyRecords(
      int year,
      int month, {
        String? type,
      }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return getRecordsByDateRange(startDate, endDate, type: type);
  }

  // Get statistics
  Future<Map<String, double>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        whereClause = 'WHERE date >= ? AND date <= ?';
        whereArgs = [
          startDate.toIso8601String(),
          endDate.add(const Duration(days: 1)).toIso8601String(),
        ];
      }

      final result = await _dbHelper.rawQuery('''
        SELECT 
          type,
          COALESCE(SUM(amount), 0) as total
        FROM ${DatabaseHelper.tableIncomeExpense}
        $whereClause
        GROUP BY type
      ''', whereArgs);

      double totalIncome = 0;
      double totalExpense = 0;

      for (final row in result) {
        if (row['type'] == 'income') {
          totalIncome = (row['total'] ?? 0).toDouble();
        } else if (row['type'] == 'expense') {
          totalExpense = (row['total'] ?? 0).toDouble();
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'balance': 0.0,
      };
    }
  }

  // Get today's statistics
  Future<Map<String, double>> getTodayStatistics() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getStatistics(startDate: startOfDay, endDate: endOfDay);
  }

  // Get monthly statistics
  Future<Map<String, double>> getMonthlyStatistics(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return getStatistics(startDate: startDate, endDate: endDate);
  }

  // Get payment method statistics
  Future<List<Map<String, dynamic>>> getPaymentMethodStatistics({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (type != null) {
        whereClause += ' AND type = ?';
        whereArgs.add(type);
      }

      if (startDate != null && endDate != null) {
        whereClause += ' AND date >= ? AND date <= ?';
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.add(const Duration(days: 1)).toIso8601String(),
        ]);
      }

      final result = await _dbHelper.rawQuery('''
        SELECT 
          payment_method,
          COUNT(*) as count,
          COALESCE(SUM(amount), 0) as total
        FROM ${DatabaseHelper.tableIncomeExpense}
        WHERE $whereClause
        GROUP BY payment_method
        ORDER BY total DESC
      ''', whereArgs);

      return result;
    } catch (e) {
      print('Error getting payment method statistics: $e');
      return [];
    }
  }
}
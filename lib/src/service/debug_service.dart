import 'package:get/get.dart';
import 'database_helper.dart';
import 'app_init_service.dart';
import 'dart:io';

class DebugService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    return await AppInitializationService.getDatabaseInfo();
  }

  // Export all data as JSON (for backup)
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final categories = await _dbHelper.query(DatabaseHelper.tableCategories);
      final products = await _dbHelper.query(DatabaseHelper.tableProducts);
      final transactions = await _dbHelper.query(DatabaseHelper.tableTransactions);
      final transactionItems = await _dbHelper.query(DatabaseHelper.tableTransactionItems);

      return {
        'categories': categories,
        'products': products,
        'transactions': transactions,
        'transaction_items': transactionItems,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error exporting data: $e');
      return {};
    }
  }

  // Clear all data and reset
  Future<void> resetDatabase() async {
    try {
      await AppInitializationService.resetAllData();
      Get.snackbar('Success', 'Database berhasil direset');
    } catch (e) {
      Get.snackbar('Error', 'Gagal reset database: $e');
    }
  }

  // Check database integrity
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final result = await _dbHelper.rawQuery('PRAGMA integrity_check');
      return result.first['integrity_check'] == 'ok';
    } catch (e) {
      print('Error checking database integrity: $e');
      return false;
    }
  }

  // Vacuum database (optimize storage)
  Future<void> vacuumDatabase() async {
    try {
      await _dbHelper.rawQuery('VACUUM');
      Get.snackbar('Success', 'Database berhasil dioptimasi');
    } catch (e) {
      Get.snackbar('Error', 'Gagal optimasi database: $e');
    }
  }

  // Get table info
  Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    try {
      return await _dbHelper.rawQuery('PRAGMA table_info($tableName)');
    } catch (e) {
      print('Error getting table info: $e');
      return [];
    }
  }

  // Execute custom SQL query (for debugging only)
  Future<List<Map<String, dynamic>>> executeCustomQuery(String query) async {
    try {
      return await _dbHelper.rawQuery(query);
    } catch (e) {
      print('Error executing custom query: $e');
      return [];
    }
  }

  // Get database file size
  Future<String> getDatabaseSize() async {
    try {
      final path = await _dbHelper.getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        return _formatBytes(size);
      }
      return 'Unknown';
    } catch (e) {
      return 'Error: $e';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Extension for File import

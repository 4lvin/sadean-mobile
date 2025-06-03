import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import 'database_helper.dart';

class CategoryService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Category>> getAllCategories() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableCategories,
        orderBy: 'name ASC',
      );

      return maps.map((map) => Category.fromJson(map)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<Category?> getCategoryById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableCategories,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Category.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting category by id: $e');
      return null;
    }
  }

  Future<Category> addCategory(String name) async {
    try {
      // Check if category with same name already exists
      final existing = await _dbHelper.query(
        DatabaseHelper.tableCategories,
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [name.trim()],
      );

      if (existing.isNotEmpty) {
        throw Exception('Kategori dengan nama "$name" sudah ada');
      }

      final newCategory = Category(
        id: const Uuid().v4(),
        name: name.trim(),
        productCount: 0,
        soldCount: 0,
      );

      await _dbHelper.insert(
        DatabaseHelper.tableCategories,
        newCategory.toJson(),
      );

      return newCategory;
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String id, String name) async {
    try {
      // Check if category exists
      final existing = await getCategoryById(id);
      if (existing == null) {
        throw Exception('Kategori tidak ditemukan');
      }

      // Check if another category with same name exists
      final duplicate = await _dbHelper.query(
        DatabaseHelper.tableCategories,
        where: 'LOWER(name) = LOWER(?) AND id != ?',
        whereArgs: [name.trim(), id],
      );

      if (duplicate.isNotEmpty) {
        throw Exception('Kategori dengan nama "$name" sudah ada');
      }

      await _dbHelper.update(
        DatabaseHelper.tableCategories,
        {'name': name.trim()},
        'id = ?',
        [id],
      );
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      // Check if category has products
      final products = await _dbHelper.query(
        DatabaseHelper.tableProducts,
        where: 'category_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (products.isNotEmpty) {
        return false; // Cannot delete category with products
      }

      final result = await _dbHelper.delete(
        DatabaseHelper.tableCategories,
        'id = ?',
        [id],
      );

      return result > 0;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  Future<void> updateProductCount(String categoryId, int count) async {
    try {
      await _dbHelper.update(
        DatabaseHelper.tableCategories,
        {'product_count': count},
        'id = ?',
        [categoryId],
      );
    } catch (e) {
      print('Error updating product count: $e');
    }
  }

  Future<void> updateSoldCount(String categoryId, int soldCount) async {
    try {
      await _dbHelper.update(
        DatabaseHelper.tableCategories,
        {'sold_count': soldCount},
        'id = ?',
        [categoryId],
      );
    } catch (e) {
      print('Error updating sold count: $e');
    }
  }

  Future<void> recalculateProductCounts() async {
    try {
      // Get all categories
      final categories = await getAllCategories();

      for (final category in categories) {
        // Count products in this category
        final productCount = await _dbHelper.rawQuery(
          'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts} WHERE category_id = ?',
          [category.id],
        );

        // Calculate total sold count for this category
        final soldCountResult = await _dbHelper.rawQuery(
          'SELECT COALESCE(SUM(sold_count), 0) as total_sold FROM ${DatabaseHelper.tableProducts} WHERE category_id = ?',
          [category.id],
        );

        final int newProductCount = productCount.first['count'] as int;
        final int newSoldCount = soldCountResult.first['total_sold'] as int;

        // Update category counts
        await _dbHelper.update(
          DatabaseHelper.tableCategories,
          {
            'product_count': newProductCount,
            'sold_count': newSoldCount,
          },
          'id = ?',
          [category.id],
        );
      }
    } catch (e) {
      print('Error recalculating product counts: $e');
    }
  }

  Future<List<Category>> getTopCategories({int limit = 5}) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableCategories,
        orderBy: 'sold_count DESC, name ASC',
        limit: limit,
      );

      return maps.map((map) => Category.fromJson(map)).toList();
    } catch (e) {
      print('Error getting top categories: $e');
      return [];
    }
  }

  Future<List<Category>> searchCategories(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableCategories,
        where: 'name LIKE ?',
        whereArgs: ['%${query.trim()}%'],
        orderBy: 'name ASC',
      );

      return maps.map((map) => Category.fromJson(map)).toList();
    } catch (e) {
      print('Error searching categories: $e');
      return [];
    }
  }
}
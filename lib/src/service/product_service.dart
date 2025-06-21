import 'dart:io';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/product_model.dart';
import 'database_helper.dart';
import 'category_service.dart';

class ProductService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CategoryService _categoryService = Get.find<CategoryService>();

  Future<List<Product>> getAllProducts() async {
    try {
      final maps = await _dbHelper.query(DatabaseHelper.tableProducts, orderBy: 'name ASC');
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final maps = await _dbHelper.query(DatabaseHelper.tableProducts, where: 'id = ?', whereArgs: [id], limit: 1);
      if (maps.isNotEmpty) {
        return Product.fromJson(_convertMapKeys(maps.first));
      }
      return null;
    } catch (e) {
      print('Error getting product by id: $e');
      return null;
    }
  }

  Future<Product> addProduct({
    required String name,
    required String categoryId,
    required String sku,
    required String barcode,
    required double costPrice,
    required double sellingPrice,
    required String unit,
    required int stock,
    required int minStock,
    File? imageFile,
    bool isStockEnabled = true,
  }) async {
    try {
      // Generate SKU if empty
      String finalSku = sku.trim();
      if (finalSku.isEmpty) {
        finalSku = await _generateUniqueSKU(categoryId);
      }

      await _validateProductData(name, categoryId, finalSku, barcode);

      String? imagePath;
      if (imageFile != null) {
        imagePath = await _saveImageFile(imageFile);
      }

      final newProduct = Product(
        id: const Uuid().v4(),
        name: name.trim(),
        categoryId: categoryId,
        imageUrl: imagePath,
        sku: finalSku,
        barcode: barcode.trim(),
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        unit: unit.trim(),
        stock: stock,
        minStock: minStock,
        soldCount: 0,
        isStockEnabled: isStockEnabled,
      );

      await _dbHelper.transaction((txn) async {
        await _dbHelper.insertTrx(txn, DatabaseHelper.tableProducts, _convertToDbMap(newProduct.toJson()));
        await _updateCategoryProductCount(categoryId, txn);
      });

      return newProduct;
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String categoryId,
    required String sku,
    required String barcode,
    required double costPrice,
    required double sellingPrice,
    required String unit,
    required int stock,
    required int minStock,
    File? imageFile,
    bool removeImage = false,
    bool? isStockEnabled,
  }) async {
    try {
      final currentProduct = await getProductById(id);
      if (currentProduct == null) throw Exception('Produk tidak ditemukan');

      await _validateProductData(name, categoryId, sku, barcode, excludeId: id);

      String? imagePath = currentProduct.imageUrl;
      if (removeImage) {
        if (imagePath != null) File(imagePath).delete().catchError((_) {});
        imagePath = null;
      } else if (imageFile != null) {
        imagePath = await _saveImageFile(imageFile);
      }

      final updateData = _convertToDbMap({
        'name': name.trim(),
        'categoryId': categoryId,
        'imageUrl': imagePath,
        'sku': sku.trim(),
        'barcode': barcode.trim(),
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'unit': unit.trim(),
        'stock': stock,
        'minStock': minStock,
        'isStockEnabled': isStockEnabled ?? currentProduct.isStockEnabled,
      });

      await _dbHelper.transaction((txn) async {
        await txn.update(DatabaseHelper.tableProducts, updateData, where: 'id = ?', whereArgs: [id]);
        if (currentProduct.categoryId != categoryId) {
          await _updateCategoryProductCount(currentProduct.categoryId, txn);
          await _updateCategoryProductCount(categoryId, txn);
        }
      });
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final product = await getProductById(id);
      if (product == null) throw Exception('Produk tidak ditemukan');

      if (product.imageUrl != null) {
        File(product.imageUrl!).delete().catchError((_) {});
      }

      await _dbHelper.transaction((txn) async {
        await txn.delete(DatabaseHelper.tableProducts, where: 'id = ?', whereArgs: [id]);
        await _updateCategoryProductCount(product.categoryId, txn);
      });
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _dbHelper.update(DatabaseHelper.tableProducts, {'stock': newStock}, 'id = ?', [productId]);
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  Future<void> updateSoldCount(String productId, int soldQuantity) async {
    try {
      final product = await getProductById(productId);
      if (product == null) throw Exception('Produk tidak ditemukan');

      final newSoldCount = product.soldCount + soldQuantity;

      // Only update stock if stock tracking is enabled
      int newStock = product.stock;
      if (product.isStockEnabled) {
        newStock = product.stock - soldQuantity;
        if (newStock < 0) throw Exception('Stok tidak mencukupi');
      }

      await _dbHelper.transaction((txn) async {
        final updateData = {
          'sold_count': newSoldCount,
        };

        // Only update stock if tracking is enabled
        if (product.isStockEnabled) {
          updateData['stock'] = newStock;
        }

        await txn.update(DatabaseHelper.tableProducts, updateData, where: 'id = ?', whereArgs: [productId]);
        await _updateCategorySoldCount(product.categoryId, txn);
      });
    } catch (e) {
      print('Error updating sold count: $e');
      rethrow;
    }
  }

  Future<void> toggleStockTracking(String productId, bool enabled) async {
    try {
      final product = await getProductById(productId);
      if (product == null) throw Exception('Produk tidak ditemukan');

      final updateData = {
        'is_stock_enabled': enabled ? 1 : 0,
      };

      // If disabling stock tracking, set stock to unlimited
      if (!enabled) {
        updateData['stock'] = 999999;
        updateData['min_stock'] = 0;
      }

      await _dbHelper.update(DatabaseHelper.tableProducts, updateData, 'id = ?', [productId]);
    } catch (e) {
      print('Error toggling stock tracking: $e');
      rethrow;
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final maps = await _dbHelper.query(DatabaseHelper.tableProducts, where: 'barcode = ?', whereArgs: [barcode.trim()], limit: 1);
      if (maps.isNotEmpty) {
        return Product.fromJson(_convertMapKeys(maps.first));
      }
      return null;
    } catch (e) {
      print('Error getting product by barcode: $e');
      return null;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final maps = await _dbHelper.query(
        DatabaseHelper.tableProducts,
        where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
        whereArgs: ['%${query.trim()}%', '%${query.trim()}%', '%${query.trim()}%'],
        orderBy: 'name ASC',
      );
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<Product?> getProductBySKU(String sku) async {
    try {
      if (sku.trim().isEmpty) return null;

      final maps = await _dbHelper.query(
          DatabaseHelper.tableProducts,
          where: 'sku = ?',
          whereArgs: [sku.trim()],
          limit: 1
      );
      if (maps.isNotEmpty) {
        return Product.fromJson(_convertMapKeys(maps.first));
      }
      return null;
    } catch (e) {
      print('Error getting product by SKU: $e');
      return null;
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final maps = await _dbHelper.query(DatabaseHelper.tableProducts, where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'name ASC');
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  Future<List<Product>> getLowStockProducts() async {
    try {
      // Only get products with stock tracking enabled and low stock
      final maps = await _dbHelper.rawQuery(
        'SELECT * FROM ${DatabaseHelper.tableProducts} WHERE is_stock_enabled = 1 AND stock <= min_stock ORDER BY stock ASC, name ASC',
      );
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting low stock products: $e');
      return [];
    }
  }

  Future<List<Product>> getOutOfStockProducts() async {
    try {
      // Only get products with stock tracking enabled and zero stock
      final maps = await _dbHelper.rawQuery(
        'SELECT * FROM ${DatabaseHelper.tableProducts} WHERE is_stock_enabled = 1 AND stock = 0 ORDER BY name ASC',
      );
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting out of stock products: $e');
      return [];
    }
  }

  Future<List<Product>> getTopProducts({int limit = 10}) async {
    try {
      final maps = await _dbHelper.query(DatabaseHelper.tableProducts, orderBy: 'sold_count DESC, name ASC', limit: limit);
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting top products: $e');
      return [];
    }
  }

  Future<List<Product>> getUnlimitedStockProducts() async {
    try {
      // Get products with stock tracking disabled
      final maps = await _dbHelper.rawQuery(
        'SELECT * FROM ${DatabaseHelper.tableProducts} WHERE is_stock_enabled = 0 ORDER BY name ASC',
      );
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting unlimited stock products: $e');
      return [];
    }
  }

  // === HELPER METHODS ===

  Future<void> _validateProductData(String name, String categoryId, String sku, String barcode, {String? excludeId}) async {
    if (name.trim().isEmpty) throw Exception('Nama produk tidak boleh kosong');

    final category = await _categoryService.getCategoryById(categoryId);
    if (category == null) throw Exception('Kategori tidak ditemukan');

    // SKU validation only if provided (not empty)
    if (sku.trim().isNotEmpty) {
      final skuWhere = excludeId != null ? 'sku = ? AND id != ?' : 'sku = ?';
      final skuArgs = excludeId != null ? [sku.trim(), excludeId] : [sku.trim()];
      final existingSku = await _dbHelper.query(DatabaseHelper.tableProducts, where: skuWhere, whereArgs: skuArgs, limit: 1);
      if (existingSku.isNotEmpty) throw Exception('SKU "$sku" sudah digunakan');
    }

    // Barcode validation (always required)
    final barcodeWhere = excludeId != null ? 'barcode = ? AND id != ?' : 'barcode = ?';
    final barcodeArgs = excludeId != null ? [barcode.trim(), excludeId] : [barcode.trim()];
    final existingBarcode = await _dbHelper.query(DatabaseHelper.tableProducts, where: barcodeWhere, whereArgs: barcodeArgs, limit: 1);
    if (existingBarcode.isNotEmpty) throw Exception('Barcode "$barcode" sudah digunakan');
  }

  Future<void> _updateCategoryProductCount(String categoryId, Transaction txn) async {
    final countResult = await txn.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts} WHERE category_id = ?',
      [categoryId],
    );
    final count = countResult.first['count'] as int;
    await txn.update(DatabaseHelper.tableCategories, {'product_count': count}, where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<void> _updateCategorySoldCount(String categoryId, Transaction txn) async {
    final soldResult = await txn.rawQuery(
      'SELECT COALESCE(SUM(sold_count), 0) as total_sold FROM ${DatabaseHelper.tableProducts} WHERE category_id = ?',
      [categoryId],
    );
    final totalSold = soldResult.first['total_sold'] as int;
    await txn.update(DatabaseHelper.tableCategories, {'sold_count': totalSold}, where: 'id = ?', whereArgs: [categoryId]);
  }

  Map<String, dynamic> _convertMapKeys(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'name': map['name'],
      'category_id': map['category_id'],
      'image_url': map['image_url'],
      'sku': map['sku'],
      'barcode': map['barcode'],
      'cost_price': map['cost_price'],
      'selling_price': map['selling_price'],
      'unit': map['unit'],
      'stock': map['stock'],
      'min_stock': map['min_stock'],
      'sold_count': map['sold_count'],
      'is_stock_enabled': map['is_stock_enabled'] ?? 1,
    };
  }

  Map<String, dynamic> _convertToDbMap(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'name': map['name'],
      'category_id': map['category_id'],
      'image_url': map['image_url'],
      'sku': map['sku'],
      'barcode': map['barcode'],
      'cost_price': map['cost_price'],
      'selling_price': map['selling_price'],
      'unit': map['unit'],
      'stock': map['stock'],
      'min_stock': map['min_stock'],
      'sold_count': map['sold_count'],
      'is_stock_enabled': map['isStockEnabled'] == true ? 1 : 0,
    };
  }

  Future<String> _saveImageFile(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(dir.path, 'images'));
    if (!await imageDir.exists()) await imageDir.create(recursive: true);

    final filename = '${const Uuid().v4()}.jpg';
    final newImage = await imageFile.copy(path.join(imageDir.path, filename));
    return newImage.path;
  }

  // Generate unique SKU automatically
  Future<String> _generateUniqueSKU(String categoryId) async {
    try {
      final category = await _categoryService.getCategoryById(categoryId);
      final categoryName = category?.name ?? 'PROD';

      // Take first 3 letters of category name (uppercase)
      final categoryCode = categoryName.length >= 3
          ? categoryName.substring(0, 3).toUpperCase()
          : categoryName.toUpperCase().padRight(3, 'X');

      String generatedSKU;
      int attempts = 0;
      const maxAttempts = 10;

      do {
        final now = DateTime.now();
        final timestamp = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

        // Add attempt number if not first attempt
        final suffix = attempts > 0 ? attempts.toString() : '';
        generatedSKU = '$categoryCode$timestamp$suffix';

        attempts++;

        // Check if SKU already exists
        final existing = await getProductBySKU(generatedSKU);
        if (existing == null) {
          break; // SKU is unique
        }

        // Wait a bit before next attempt to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 100));

      } while (attempts < maxAttempts);

      if (attempts >= maxAttempts) {
        // Fallback to UUID-based SKU
        generatedSKU = '${categoryCode}${const Uuid().v4().substring(0, 8).toUpperCase()}';
      }

      return generatedSKU;
    } catch (e) {
      print('Error generating unique SKU: $e');
      // Fallback to simple UUID-based SKU
      return 'PROD${const Uuid().v4().substring(0, 8).toUpperCase()}';
    }
  }

  // Check if SKU exists (for validation)
  Future<bool> isSkuExists(String sku, {String? excludeId}) async {
    try {
      if (sku.trim().isEmpty) return false;

      final where = excludeId != null ? 'sku = ? AND id != ?' : 'sku = ?';
      final whereArgs = excludeId != null ? [sku.trim(), excludeId] : [sku.trim()];

      final result = await _dbHelper.query(
        DatabaseHelper.tableProducts,
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking SKU existence: $e');
      return false;
    }
  }

  // Check if Barcode exists (for validation)
  Future<bool> isBarcodeExists(String barcode, {String? excludeId}) async {
    try {
      if (barcode.trim().isEmpty) return false;

      final where = excludeId != null ? 'barcode = ? AND id != ?' : 'barcode = ?';
      final whereArgs = excludeId != null ? [barcode.trim(), excludeId] : [barcode.trim()];

      final result = await _dbHelper.query(
        DatabaseHelper.tableProducts,
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking barcode existence: $e');
      return false;
    }
  }
}
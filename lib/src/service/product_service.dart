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
  }) async {
    try {
      await _validateProductData(name, categoryId, sku, barcode);

      String? imagePath;
      if (imageFile != null) {
        imagePath = await _saveImageFile(imageFile);
      }

      final newProduct = Product(
        id: const Uuid().v4(),
        name: name.trim(),
        categoryId: categoryId,
        imageUrl: imagePath,
        sku: sku.trim(),
        barcode: barcode.trim(),
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        unit: unit.trim(),
        stock: stock,
        minStock: minStock,
        soldCount: 0,
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

      final newStock = product.stock - soldQuantity;
      final newSoldCount = product.soldCount + soldQuantity;

      if (newStock < 0) throw Exception('Stok tidak mencukupi');

      await _dbHelper.transaction((txn) async {
        await txn.update(DatabaseHelper.tableProducts, {
          'stock': newStock,
          'sold_count': newSoldCount,
        }, where: 'id = ?', whereArgs: [productId]);

        await _updateCategorySoldCount(product.categoryId, txn);
      });
    } catch (e) {
      print('Error updating sold count: $e');
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
      final maps = await _dbHelper.rawQuery(
        'SELECT * FROM ${DatabaseHelper.tableProducts} WHERE stock <= min_stock ORDER BY stock ASC, name ASC',
      );
      return maps.map((map) => Product.fromJson(_convertMapKeys(map))).toList();
    } catch (e) {
      print('Error getting low stock products: $e');
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

  // === HELPER METHODS ===

  Future<void> _validateProductData(String name, String categoryId, String sku, String barcode, {String? excludeId}) async {
    if (name.trim().isEmpty) throw Exception('Nama produk tidak boleh kosong');

    final category = await _categoryService.getCategoryById(categoryId);
    if (category == null) throw Exception('Kategori tidak ditemukan');

    final skuWhere = excludeId != null ? 'sku = ? AND id != ?' : 'sku = ?';
    final skuArgs = excludeId != null ? [sku.trim(), excludeId] : [sku.trim()];
    final existingSku = await _dbHelper.query(DatabaseHelper.tableProducts, where: skuWhere, whereArgs: skuArgs, limit: 1);
    if (existingSku.isNotEmpty) throw Exception('SKU "$sku" sudah digunakan');

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
}

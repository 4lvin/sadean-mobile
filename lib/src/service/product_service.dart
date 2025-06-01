import 'dart:io';

import 'package:get/get.dart';
import 'package:sadean/src/service/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

import '../models/product_model.dart';
import 'category_service.dart';

class ProductService extends GetxService {
  final SecureStorageService _storage = Get.find<SecureStorageService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  static const String _storageKey = 'products';

  Future<List<Product>> getAllProducts() async {
    try {
      final List<Map<String, dynamic>> data = await _storage.getList(_storageKey);
      return data.map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
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
    final products = await getAllProducts();

    // Check for duplicate SKU or barcode
    if (products.any((p) => p.sku == sku)) {
      throw Exception('SKU sudah digunakan');
    }
    if (products.any((p) => p.barcode == barcode)) {
      throw Exception('Barcode sudah digunakan');
    }

    // Convert image to Base64 if provided
    String? imageBase64;
    if (imageFile != null) {
      imageBase64 = await _storage.imageToBase64(imageFile);
    }

    final newProduct = Product(
      id: const Uuid().v4(),
      name: name,
      categoryId: categoryId,
      imageUrl: imageBase64,
      sku: sku,
      barcode: barcode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      unit: unit,
      stock: stock,
      minStock: minStock,
      soldCount: 0,
    );

    products.add(newProduct);
    await _saveAllProducts(products);

    // Update category product count
    await _updateCategoryProductCount();

    return newProduct;
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
    final products = await getAllProducts();
    final index = products.indexWhere((p) => p.id == id);

    if (index == -1) {
      throw Exception('Produk tidak ditemukan');
    }

    final currentProduct = products[index];

    // Check for duplicate SKU or barcode (excluding current product)
    if (products.any((p) => p.id != id && p.sku == sku)) {
      throw Exception('SKU sudah digunakan');
    }
    if (products.any((p) => p.id != id && p.barcode == barcode)) {
      throw Exception('Barcode sudah digunakan');
    }

    // Handle image
    String? imageBase64 = currentProduct.imageUrl;
    if (removeImage) {
      imageBase64 = null;
    } else if (imageFile != null) {
      imageBase64 = await _storage.imageToBase64(imageFile);
    }

    products[index] = Product(
      id: id,
      name: name,
      categoryId: categoryId,
      imageUrl: imageBase64,
      sku: sku,
      barcode: barcode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      unit: unit,
      stock: stock,
      minStock: minStock,
      soldCount: currentProduct.soldCount,
    );

    await _saveAllProducts(products);
    await _updateCategoryProductCount();
  }

  Future<void> deleteProduct(String id) async {
    final products = await getAllProducts();
    products.removeWhere((p) => p.id == id);
    await _saveAllProducts(products);
    await _updateCategoryProductCount();
  }

  Future<void> updateStock(String productId, int newStock) async {
    final products = await getAllProducts();
    final index = products.indexWhere((p) => p.id == productId);

    if (index != -1) {
      final product = products[index];
      products[index] = Product(
        id: product.id,
        name: product.name,
        categoryId: product.categoryId,
        imageUrl: product.imageUrl,
        sku: product.sku,
        barcode: product.barcode,
        costPrice: product.costPrice,
        sellingPrice: product.sellingPrice,
        unit: product.unit,
        stock: newStock,
        minStock: product.minStock,
        soldCount: product.soldCount,
      );
      await _saveAllProducts(products);
    }
  }

  Future<void> updateSoldCount(String productId, int soldQuantity) async {
    final products = await getAllProducts();
    final index = products.indexWhere((p) => p.id == productId);

    if (index != -1) {
      final product = products[index];
      products[index] = Product(
        id: product.id,
        name: product.name,
        categoryId: product.categoryId,
        imageUrl: product.imageUrl,
        sku: product.sku,
        barcode: product.barcode,
        costPrice: product.costPrice,
        sellingPrice: product.sellingPrice,
        unit: product.unit,
        stock: product.stock - soldQuantity, // Reduce stock
        minStock: product.minStock,
        soldCount: product.soldCount + soldQuantity,
      );
      await _saveAllProducts(products);
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final lowerQuery = query.toLowerCase();

    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.sku.toLowerCase().contains(lowerQuery) ||
          product.barcode.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final products = await getAllProducts();
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.stock <= p.minStock).toList();
  }

  Future<void> _saveAllProducts(List<Product> products) async {
    final data = products.map((product) => product.toJson()).toList();
    await _storage.saveList(_storageKey, data);
  }

  Future<void> _updateCategoryProductCount() async {
    final products = await getAllProducts();
    final categories = await _categoryService.getAllCategories();

    for (final category in categories) {
      final count = products.where((p) => p.categoryId == category.id).length;
      await _categoryService.updateProductCount(category.id, count);
    }
  }
}
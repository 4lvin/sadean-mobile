import 'package:get/get.dart';
import 'package:sadean/src/service/product_service.dart';
import 'package:sadean/src/service/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';

class CategoryService extends GetxService {
  final SecureStorageService _storage = Get.find<SecureStorageService>();
  static const String _storageKey = 'categories';

  Future<List<Category>> getAllCategories() async {
    try {
      final List<Map<String, dynamic>> data = await _storage.getList(_storageKey);
      return data.map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<Category> addCategory(String name) async {
    final categories = await getAllCategories();

    final newCategory = Category(
      id: const Uuid().v4(),
      name: name,
      productCount: 0,
      soldCount: 0,
    );

    categories.add(newCategory);
    await _saveAllCategories(categories);

    return newCategory;
  }

  Future<void> updateCategory(String id, String name) async {
    final categories = await getAllCategories();
    final index = categories.indexWhere((cat) => cat.id == id);

    if (index != -1) {
      categories[index] = Category(
        id: id,
        name: name,
        productCount: categories[index].productCount,
        soldCount: categories[index].soldCount,
      );
      await _saveAllCategories(categories);
    }
  }

  Future<bool> deleteCategory(String id) async {
    // Check if category has products
    final products = await Get.find<ProductService>().getAllProducts();
    final hasProducts = products.any((product) => product.categoryId == id);

    if (hasProducts) {
      return false; // Cannot delete category with products
    }

    final categories = await getAllCategories();
    categories.removeWhere((cat) => cat.id == id);
    await _saveAllCategories(categories);

    return true;
  }

  Future<void> updateProductCount(String categoryId, int count) async {
    final categories = await getAllCategories();
    final index = categories.indexWhere((cat) => cat.id == categoryId);

    if (index != -1) {
      categories[index] = Category(
        id: categories[index].id,
        name: categories[index].name,
        productCount: count,
        soldCount: categories[index].soldCount,
      );
      await _saveAllCategories(categories);
    }
  }

  Future<void> _saveAllCategories(List<Category> categories) async {
    final data = categories.map((cat) => cat.toJson()).toList();
    await _storage.saveList(_storageKey, data);
  }
}
import 'package:get/get.dart';
import 'package:sadean/src/service/category_service.dart';
import 'package:sadean/src/service/product_service.dart';
import 'package:sadean/src/service/secure_storage_service.dart';
import 'package:sadean/src/service/transaction_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    // Initialize services in correct order
    Get.put(SecureStorageService());
    Get.put(CategoryService());
    Get.put(ProductService());
    Get.put(TransactionService());

    // Initialize sample data if empty
    await _initializeSampleData();
  }

  static Future<void> _initializeSampleData() async {
    final categoryService = Get.find<CategoryService>();
    final productService = Get.find<ProductService>();

    final categories = await categoryService.getAllCategories();
    final products = await productService.getAllProducts();

    // Add sample categories if empty
    // if (categories.isEmpty) {
    //   await categoryService.addCategory('Makanan');
    //   await categoryService.addCategory('Minuman');
    //   await categoryService.addCategory('Snack');
    // }
    //
    // // Add sample products if empty
    // if (products.isEmpty) {
    //   final updatedCategories = await categoryService.getAllCategories();
    //   final foodCategoryId = updatedCategories.firstWhere((c) => c.name == 'Makanan').id;
    //   final drinkCategoryId = updatedCategories.firstWhere((c) => c.name == 'Minuman').id;
    //
    //   await productService.addProduct(
    //     name: 'Nasi Goreng',
    //     categoryId: foodCategoryId,
    //     sku: 'NG001',
    //     barcode: '8995678123456',
    //     costPrice: 15000,
    //     sellingPrice: 25000,
    //     unit: 'porsi',
    //     stock: 20,
    //     minStock: 5,
    //   );
    //
    //   await productService.addProduct(
    //     name: 'Es Teh Manis',
    //     categoryId: drinkCategoryId,
    //     sku: 'ETM001',
    //     barcode: '8995678123457',
    //     costPrice: 3000,
    //     sellingPrice: 8000,
    //     unit: 'gelas',
    //     stock: 50,
    //     minStock: 10,
    //   );
    // }
  }
}

import 'package:get/get.dart';
import 'package:sadean/src/service/category_service.dart';
import 'package:sadean/src/service/product_service.dart';
import 'package:sadean/src/service/transaction_service.dart';
import 'database_helper.dart';
import 'income_expense_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    // Initialize database first
    await DatabaseHelper.instance.database;

    // Initialize services in correct order
    Get.put(CategoryService());
    Get.put(ProductService());
    Get.put(TransactionService());
    Get.put<IncomeExpenseService>(IncomeExpenseService(), permanent: true);

    // Initialize sample data if empty (optional)
    await _initializeSampleData();
  }

  static Future<void> _initializeSampleData() async {
    try {
      final categoryService = Get.find<CategoryService>();
      final productService = Get.find<ProductService>();

      final categories = await categoryService.getAllCategories();
      final products = await productService.getAllProducts();

      // Add sample categories if empty
      // if (categories.isEmpty) {
      //   print('Adding sample categories...');
      //   final foodCategory = await categoryService.addCategory('Makanan');
      //   final drinkCategory = await categoryService.addCategory('Minuman');
      //   final snackCategory = await categoryService.addCategory('Snack');
      //
      //   // Add sample products if empty
      //   if (products.isEmpty) {
      //     print('Adding sample products...');
      //
      //     await productService.addProduct(
      //       name: 'Nasi Goreng',
      //       categoryId: foodCategory.id,
      //       sku: 'NG001',
      //       barcode: '8995678123456',
      //       costPrice: 15000,
      //       sellingPrice: 25000,
      //       unit: 'porsi',
      //       stock: 20,
      //       minStock: 5,
      //     );
      //
      //     await productService.addProduct(
      //       name: 'Es Teh Manis',
      //       categoryId: drinkCategory.id,
      //       sku: 'ETM001',
      //       barcode: '8995678123457',
      //       costPrice: 3000,
      //       sellingPrice: 8000,
      //       unit: 'gelas',
      //       stock: 50,
      //       minStock: 10,
      //     );
      //
      //     await productService.addProduct(
      //       name: 'Kerupuk',
      //       categoryId: snackCategory.id,
      //       sku: 'KRP001',
      //       barcode: '8995678123458',
      //       costPrice: 2000,
      //       sellingPrice: 5000,
      //       unit: 'bungkus',
      //       stock: 30,
      //       minStock: 8,
      //     );
      //
      //     await productService.addProduct(
      //       name: 'Ayam Bakar',
      //       categoryId: foodCategory.id,
      //       sku: 'AB001',
      //       barcode: '8995678123459',
      //       costPrice: 20000,
      //       sellingPrice: 35000,
      //       unit: 'porsi',
      //       stock: 15,
      //       minStock: 3,
      //     );
      //
      //     await productService.addProduct(
      //       name: 'Jus Jeruk',
      //       categoryId: drinkCategory.id,
      //       sku: 'JJ001',
      //       barcode: '8995678123460',
      //       costPrice: 5000,
      //       sellingPrice: 12000,
      //       unit: 'gelas',
      //       stock: 25,
      //       minStock: 5,
      //     );
      //
      //     print('Sample data initialized successfully');
      //   }
      // }
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }

  // Method to reset all data (useful for testing)
  static Future<void> resetAllData() async {
    try {
      await DatabaseHelper.instance.clearAllData();
      print('All data cleared successfully');

      // Optionally reinitialize sample data
      await _initializeSampleData();
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

  // Method to get database info (for debugging)
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      final categoriesCount = await dbHelper.rawQuery(
          'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableCategories}'
      );

      final productsCount = await dbHelper.rawQuery(
          'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts}'
      );

      final transactionsCount = await dbHelper.rawQuery(
          'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTransactions}'
      );

      final dbPath = await dbHelper.getDatabasePath();

      return {
        'database_path': dbPath,
        'categories_count': categoriesCount.first['count'],
        'products_count': productsCount.first['count'],
        'transactions_count': transactionsCount.first['count'],
      };
    } catch (e) {
      print('Error getting database info: $e');
      return {};
    }
  }
}
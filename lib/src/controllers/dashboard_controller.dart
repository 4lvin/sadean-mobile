import 'package:get/get.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../service/category_service.dart';
import '../service/product_service.dart';
import '../service/transaction_service.dart';

class DashboardController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();

  final RxInt transactionCount = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalProfit = 0.0.obs;
  final RxList<Product> topProducts = <Product>[].obs;
  final RxList<Category> topCategories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;

    try {
      final stats = await _transactionService.getDashboardStats();
      final products = await _productService.getAllProducts();
      final categories = await _categoryService.getAllCategories();

      transactionCount.value = stats['transactionCount']!.toInt();
      totalRevenue.value = stats['revenue']!;
      totalExpenses.value = stats['cost']!;
      totalProfit.value = stats['profit']!;

      // Sort products by sold count and take top 3
      products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      topProducts.assignAll(products.take(3).toList());

      // Sort categories by sold count and take top 3
      categories.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      topCategories.assignAll(categories.take(3).toList());

    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }
}


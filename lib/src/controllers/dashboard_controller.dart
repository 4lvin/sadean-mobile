// Updated lib/src/controllers/dashboard_controller.dart

import 'package:get/get.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../service/category_service.dart';
import '../service/product_service.dart';
import '../service/transaction_service.dart';
import '../service/income_expense_service.dart';

class DashboardController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final IncomeExpenseService _incomeExpenseService = Get.find<IncomeExpenseService>();

  final RxInt transactionCount = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalProfit = 0.0.obs;
  final RxList<Product> topProducts = <Product>[].obs;
  final RxList<Category> topCategories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  // New observables for income/expense
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpense = 0.0.obs;
  final RxDouble netBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;

    try {
      // Fetch transaction stats
      final stats = await _transactionService.getDashboardStats();
      final products = await _productService.getAllProducts();
      final categories = await _categoryService.getAllCategories();

      transactionCount.value = stats['transactionCount']!.toInt();
      totalRevenue.value = stats['revenue']!;

      // Fetch income/expense stats
      final incomeExpenseStats = await _incomeExpenseService.getStatistics();
      totalIncome.value = incomeExpenseStats['totalIncome'] ?? 0.0;
      totalExpense.value = incomeExpenseStats['totalExpense'] ?? 0.0;
      netBalance.value = incomeExpenseStats['balance'] ?? 0.0;

      // Use totalExpense from income_expense table for dashboard
      totalExpenses.value = totalExpense.value;

      // Calculate profit as revenue minus cost from transactions
      totalProfit.value = stats['revenue']! - stats['cost']!;

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

  String formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
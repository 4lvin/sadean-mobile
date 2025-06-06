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
  final RxDouble totalRevenue = 0.0.obs; // Laba transaksi + income
  final RxDouble totalExpenses = 0.0.obs; // Expense dari income_expense
  final RxDouble totalProfit = 0.0.obs; // Total revenue - total expenses
  final RxList<Product> topProducts = <Product>[].obs;
  final RxList<Category> topCategories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  // Detailed breakdown observables
  final RxDouble transactionProfit = 0.0.obs; // Laba dari penjualan
  final RxDouble additionalIncome = 0.0.obs; // Income dari income_expense
  final RxDouble businessExpenses = 0.0.obs; // Expense dari income_expense
  final RxDouble netBalance = 0.0.obs; // Total revenue - total expenses

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

      // Transaction data
      transactionCount.value = stats['transactionCount']!.toInt();
      transactionProfit.value = stats['profit']!; // Laba dari penjualan

      // Fetch income/expense stats
      final incomeExpenseStats = await _incomeExpenseService.getStatistics();
      additionalIncome.value = incomeExpenseStats['totalIncome'] ?? 0.0;
      businessExpenses.value = incomeExpenseStats['totalExpense'] ?? 0.0;

      // Calculate total revenue (laba transaksi + pendapatan income)
      totalRevenue.value = transactionProfit.value + additionalIncome.value;

      // Total expenses (hanya dari income_expense table)
      totalExpenses.value = businessExpenses.value;

      // Calculate net profit (total revenue - total expenses)
      totalProfit.value = totalRevenue.value - totalExpenses.value;
      netBalance.value = totalProfit.value;

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

  // Helper method to get breakdown data
  Map<String, double> getRevenueBreakdown() {
    return {
      'transactionProfit': transactionProfit.value,
      'additionalIncome': additionalIncome.value,
      'totalRevenue': totalRevenue.value,
    };
  }

  // Helper method to get expense breakdown
  Map<String, double> getExpenseBreakdown() {
    return {
      'businessExpenses': businessExpenses.value,
      'totalExpenses': totalExpenses.value,
    };
  }

  String formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
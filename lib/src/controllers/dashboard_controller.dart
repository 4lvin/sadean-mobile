// Updated lib/src/controllers/dashboard_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/service/secure_storage_service.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../routers/constant.dart';
import '../service/api_service.dart';
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
  final ApiProvider _apiProvider = ApiProvider();

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }


  Future subscribe() async {
    try {
      isLoading.value = true;
      var response = await _apiProvider.checkSubscribe();
      if (response != null) {
        print(response);
        if (response['status'] == true) {
          isLoading.value = false;
          if(response['data']['subscriptions'][0]['status'] != "active") {
            Get.dialog(
              WillPopScope(
                onWillPop: () async => false, // Mencegah dismiss dengan tombol back
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 10,
                  title: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color: Colors.red.shade600,
                            size: 40,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Langganan Tidak Aktif",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  content: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Anda perlu berlangganan untuk melanjutkan menggunakan fitur premium aplikasi ini.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigasi ke halaman langganan
                              // Get.back(); // Hapus jika ingin benar-benar tidak bisa ditutup
                              // Get.toNamed('/subscription'); // Contoh navigasi
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              shadowColor: Colors.red.shade200,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Langganan Sekarang",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  titlePadding: EdgeInsets.all(20),
                  contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                ),
              ),
              barrierDismissible: false, // Mencegah tap di luar dialog untuk menutup
            );
          }
        } else {
          isLoading.value = false;
          if(response['message'] == "Unauthenticated.") {
            await SecureStorageService().clearAll();
            // Clear user data and navigate to login
            Get.offAllNamed(loginRoute);
            Get.snackbar(
              "Logout",
              "Berhasil keluar dari aplikasi",
              snackPosition: SnackPosition.TOP,
            );
          }
        }
      } else {
        isLoading.value = false;
        Get.rawSnackbar(message: "Response Null");
      }
    } catch (e) {
      isLoading.value = false;
      Get.rawSnackbar(message: e.toString());
      rethrow;
    }
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;

    try {
      // Fetch transaction stats
      final stats = await _transactionService.getDashboardStats();
      final products = await _productService.getAllProducts();
      final categories = await _categoryService.getAllCategories();
      subscribe();
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
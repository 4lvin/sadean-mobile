import 'package:get/get.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

class DashboardController extends GetxController {
  final RxInt transactionCount = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalProfit = 0.0.obs;
  final RxList<Product> topProducts = <Product>[].obs;
  final RxList<Category> topCategories = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  void fetchDashboardData() {
    // In a real app, this would come from a service or repository
    // For now, let's set some sample data
    transactionCount.value = 125;
    totalRevenue.value = 5750000;
    totalExpenses.value = 4200000;
    totalProfit.value = totalRevenue.value - totalExpenses.value;

    // Populate top products
    topProducts.value = [
      Product(
        id: '1',
        name: 'Nasi Goreng',
        categoryId: '1',
        sku: 'NG001',
        barcode: '8995678123456',
        costPrice: 15000,
        sellingPrice: 25000,
        unit: 'porsi',
        stock: 0,
        minStock: 0,
        soldCount: 48,
      ),
      Product(
        id: '2',
        name: 'Es Teh Manis',
        categoryId: '2',
        sku: 'ETM001',
        barcode: '8995678123457',
        costPrice: 3000,
        sellingPrice: 8000,
        unit: 'gelas',
        stock: 0,
        minStock: 0,
        soldCount: 42,
      ),
      Product(
        id: '3',
        name: 'Ayam Goreng',
        categoryId: '1',
        sku: 'AG001',
        barcode: '8995678123458',
        costPrice: 12000,
        sellingPrice: 20000,
        unit: 'porsi',
        stock: 0,
        minStock: 0,
        soldCount: 35,
      ),
    ];

    // Populate top categories
    topCategories.value = [
      Category(
        id: '1',
        name: 'Makanan',
        soldCount: 120,
      ),
      Category(
        id: '2',
        name: 'Minuman',
        soldCount: 95,
      ),
      Category(
        id: '3',
        name: 'Snack',
        soldCount: 60,
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/view/dashboard/widgets/top_category.dart';
import 'package:sadean/src/view/dashboard/widgets/top_product.dart';
import '../../controllers/dashboard_controller.dart';
import 'widgets/summary_card.dart';

class DashboardView extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Obx(() => IconButton(
            icon: controller.isLoading.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh),
            onPressed: controller.isLoading.value ? null : () => controller.fetchDashboardData(),
          )),
        ],
      ),
      body: Obx(() => RefreshIndicator(
        onRefresh: () => controller.fetchDashboardData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards in a grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SummaryCard(
                    title: 'Total Transaksi',
                    value: '${controller.transactionCount.value}',
                    icon: Icons.receipt,
                    color: Colors.blue,
                  ),
                  SummaryCard(
                    title: 'Pendapatan',
                    value: 'Rp ${formatCurrency(controller.totalRevenue.value)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                  SummaryCard(
                    title: 'Pengeluaran',
                    value: 'Rp ${formatCurrency(controller.totalExpenses.value)}',
                    icon: Icons.money_off,
                    color: Colors.red,
                  ),
                  SummaryCard(
                    title: 'Laba',
                    value: 'Rp ${formatCurrency(controller.totalProfit.value)}',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Top products section
              const Text(
                'Produk Terlaku',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              controller.topProducts.isEmpty
                  ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada data penjualan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.topProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.topProducts[index];
                  return TopProductItem(
                    rank: index + 1,
                    name: product.name,
                    soldCount: product.soldCount,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Top categories section
              const Text(
                'Kategori Terlaku',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              controller.topCategories.isEmpty
                  ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada data kategori',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.topCategories.length,
                itemBuilder: (context, index) {
                  final category = controller.topCategories[index];
                  return TopCategoryItem(
                    rank: index + 1,
                    name: category.name,
                    soldCount: category.soldCount,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Quick actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aksi Cepat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Get.toNamed('/transaction'),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Transaksi Baru'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Get.toNamed('/products/add'),
                              icon: const Icon(Icons.add_box),
                              label: const Text('Tambah Produk'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  String formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
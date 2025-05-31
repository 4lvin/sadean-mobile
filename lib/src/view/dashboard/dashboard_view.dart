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
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.fetchDashboardData(),
          ),
        ],
      ),
      body: Obx(() => RefreshIndicator(
        onRefresh: () async => controller.fetchDashboardData(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards in a grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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

              SizedBox(height: 24),

              // Top products section
              Text(
                'Produk Terlaku',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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

              SizedBox(height: 24),

              // Top categories section
              Text(
                'Kategori Terlaku',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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
            ],
          ),
        ),
      )),
    );
  }

  String formatCurrency(double value) {
    // Format as thousand separator
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
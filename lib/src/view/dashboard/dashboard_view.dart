import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
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
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _showFilterDialog(),
          ),
          Obx(
            () => IconButton(
              icon:
                  controller.isLoading.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.refresh, color: Colors.white),
              onPressed:
                  controller.isLoading.value
                      ? null
                      : () => controller.fetchDashboardData(),
            ),
          ),
        ],
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () => controller.fetchDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),

                // Filter indicator
                Obx(
                  () => Card(
                    color: Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Filter: ${controller.selectedFilter.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                          if (controller.selectedFilter.value == 'Custom' &&
                              controller.startDate.value != null &&
                              controller.endDate.value != null) ...[
                            SizedBox(width: 8),
                            Text(
                              '(${_formatDate(controller.startDate.value!)} - ${_formatDate(controller.endDate.value!)})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          Spacer(),
                          InkWell(
                            onTap: () => _showFilterDialog(),
                            child: Text(
                              'Ubah',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Main Summary cards in a grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3 / 2.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SummaryCard(
                      title: ' Total Transaksi',
                      value: '${controller.transactionCount.value}',
                      icon: Icons.receipt,
                      color: Colors.blue,
                      onTap: () => _showTransactionBreakdown(),
                    ),
                    SummaryCard(
                      title: ' Total Penjualan',
                      value:
                          'Rp ${formatCurrency(controller.totalSales.value)}',
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      subtitle: 'Omzet Penjualan',
                      onTap: () => _showSalesBreakdown(),
                    ),
                    SummaryCard(
                      title: ' Pendapatan',
                      value:
                          'Rp ${formatCurrency(controller.totalRevenue.value)}',
                      icon: Icons.trending_up,
                      color: Colors.green,
                      subtitle: 'Laba Penjualan + Income',
                      onTap: () => _showRevenueBreakdown(),
                    ),
                    SummaryCard(
                      title: ' Pengeluaran',
                      value:
                          'Rp ${formatCurrency(controller.totalExpenses.value)}',
                      icon: Icons.trending_down,
                      color: Colors.red,
                      subtitle: ' Pengeluaran',
                      onTap: () => _showExpenseBreakdown(),
                    ),
                    SummaryCard(
                      title: ' Laba Penjualan',
                      value:
                          'Rp ${formatCurrency(controller.transactionProfit.value)}',
                      icon: Icons.local_atm,
                      color: Colors.indigo,
                      subtitle: 'Laba dari Transaksi',
                      onTap: () => _showTransactionProfitBreakdown(),
                    ),
                    SummaryCard(
                      title: ' Laba Bersih',
                      value:
                          'Rp ${formatCurrency(controller.totalProfit.value)}',
                      icon: Icons.account_balance_wallet,
                      color:
                          controller.totalProfit.value >= 0
                              ? Colors.purple
                              : Colors.red,
                      subtitle: 'Pendapatan - Pengeluaran',
                      onTap: () => _showProfitBreakdown(),
                    ),
                  ],
                ),

                // Revenue breakdown summary
                _buildRevenueBreakdownCard(),

                const SizedBox(height: 24),

                // Top products section
                const Text(
                  'Produk Terlaku',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.filter_list, color: primaryColor),
            SizedBox(width: 8),
            Text('Filter Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Semua', 'Tampilkan semua data'),
            _buildFilterOption('Hari Ini', 'Data hari ini'),
            _buildFilterOption('Kemarin', 'Data kemarin'),
            _buildFilterOption('Bulan Ini', 'Data bulan ini'),
            Divider(),
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Custom Range'),
              subtitle: Text('Pilih rentang tanggal'),
              onTap: () {
                Get.back();
                _showCustomDatePicker();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String filter, String description) {
    return Obx(
      () => ListTile(
        leading: Radio<String>(
          value: filter,
          groupValue: controller.selectedFilter.value,
          onChanged: (value) {
            if (value != null) {
              controller.setFilter(value);
              Get.back();
            }
          },
        ),
        title: Text(filter),
        subtitle: Text(description),
        onTap: () {
          controller.setFilter(filter);
          Get.back();
        },
      ),
    );
  }

  void _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          controller.startDate.value != null && controller.endDate.value != null
              ? DateTimeRange(
                start: controller.startDate.value!,
                end: controller.endDate.value!,
              )
              : null,
    );

    if (picked != null) {
      controller.setCustomDateRange(picked.start, picked.end);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildRevenueBreakdownCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Rincian Keuangan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBreakdownRow(
              'Total Penjualan',
              controller.totalSales.value,
              Colors.orange,
              Icons.shopping_cart,
            ),
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'Laba Penjualan',
              controller.transactionProfit.value,
              Colors.indigo,
              Icons.local_atm,
            ),
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'Pendapatan Lain',
              controller.additionalIncome.value,
              Colors.green,
              Icons.attach_money,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Total Pendapatan',
              controller.totalRevenue.value,
              Colors.green.shade700,
              Icons.trending_up,
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'Total Pengeluaran',
              controller.totalExpenses.value,
              Colors.red,
              Icons.trending_down,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Laba Bersih',
              controller.totalProfit.value,
              controller.totalProfit.value >= 0 ? Colors.purple : Colors.red,
              Icons.account_balance_wallet,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ),
        Text(
          'Rp ${formatCurrency(amount)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showTransactionBreakdown() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Detail Transaksi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow(
              'Total Transaksi',
              '${controller.transactionCount.value}',
            ),
            _buildDialogRow('Filter', controller.selectedFilter.value),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showSalesBreakdown() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Detail Penjualan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow(
              'Total Penjualan',
              'Rp ${formatCurrency(controller.totalSales.value)}',
            ),
            _buildDialogRow(
              'Jumlah Transaksi',
              '${controller.transactionCount.value}',
            ),
            _buildDialogRow(
              'Rata-rata per Transaksi',
              controller.transactionCount.value > 0
                  ? 'Rp ${formatCurrency(controller.totalSales.value / controller.transactionCount.value)}'
                  : 'Rp 0',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showRevenueBreakdown() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Rincian Pendapatan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow(
              'Total Penjualan',
              'Rp ${formatCurrency(controller.totalSales.value)}',
            ),
            _buildDialogRow(
              'Pendapatan Lain',
              'Rp ${formatCurrency(controller.additionalIncome.value)}',
            ),
            const Divider(),
            _buildDialogRow(
              'Total Pendapatan',
              'Rp ${formatCurrency(controller.totalRevenue.value)}',
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showExpenseBreakdown() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.trending_down, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Rincian Pengeluaran'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow(
              'Pengeluaran Bisnis',
              'Rp ${formatCurrency(controller.businessExpenses.value)}',
            ),
            const Divider(),
            _buildDialogRow(
              'Total Pengeluaran',
              'Rp ${formatCurrency(controller.totalExpenses.value)}',
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showTransactionProfitBreakdown() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_atm, color: Colors.indigo),
            const SizedBox(width: 8),
            const Text('Detail Laba Penjualan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow(
              'Total Penjualan',
              'Rp ${formatCurrency(controller.totalSales.value)}',
            ),
            _buildDialogRow(
              'Laba Penjualan',
              'Rp ${formatCurrency(controller.transactionProfit.value)}',
            ),
            _buildDialogRow(
              'Margin Laba',
              controller.totalSales.value > 0
                  ? '${((controller.transactionProfit.value / controller.totalSales.value) * 100).toStringAsFixed(1)}%'
                  : '0%',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Tutup')),
        ],
      ),
    );
  }

  void _showProfitBreakdown() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color:
                  controller.totalProfit.value >= 0
                      ? Colors.purple
                      : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Rincian Laba Bersih'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow(
              'Total Pendapatan',
              'Rp ${formatCurrency(controller.totalRevenue.value)}',
            ),
            _buildDialogRow(
              'Total Pengeluaran',
              'Rp ${formatCurrency(controller.totalExpenses.value)}',
            ),
            const Divider(),
            _buildDialogRow(
              'Laba Bersih',
              'Rp ${formatCurrency(controller.totalProfit.value)}',
              isBold: true,
              color:
                  controller.totalProfit.value >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildDialogRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

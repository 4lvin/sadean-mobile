import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import 'package:sadean/src/controllers/setting_controller.dart';
import 'package:sadean/src/view/history/history_detail.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/income_expense_controller.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../models/income_expense_model.dart';
import '../../service/thermal_print_service.dart';
import '../../service/transaction_service.dart';
import '../transaction/transaction_detail.dart';

class HistoryView extends StatelessWidget {
  final HistoryController controller = Get.find<HistoryController>();
  final CustomerController customerController = Get.put(CustomerController());
  final IncomeExpenseController incomeExpenseController = Get.put(
    IncomeExpenseController(),
  );
  final BluetoothPrintService _printService = BluetoothPrintService();
  final SettingsController setController = Get.find<SettingsController>();

  // Tab controller untuk switching antara transaksi dan income/expense
  final RxInt selectedTabIndex = 0.obs;

  // Combined statistics
  final RxDouble totalTransactionProfit = 0.0.obs;
  final RxDouble totalAdditionalIncome = 0.0.obs;
  final RxDouble totalRevenue = 0.0.obs; // Laba transaksi + income
  final RxDouble totalExpenses = 0.0.obs; // Expense dari income_expense
  final RxDouble netProfit = 0.0.obs; // Total revenue - total expenses

  @override
  Widget build(BuildContext context) {
    // Calculate combined statistics when data changes
    ever(controller.transactions, _calculateCombinedStats);
    ever(incomeExpenseController.allRecords, _calculateCombinedStats);

    // Initial calculation
    _calculateCombinedStats([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterOptions(),
          ),
          Obx(
                () => IconButton(
              icon:
              (selectedTabIndex.value == 0
                  ? controller.isLoading.value
                  : incomeExpenseController.isLoading.value)
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed:
              (selectedTabIndex.value == 0
                  ? controller.isLoading.value
                  : incomeExpenseController.isLoading.value)
                  ? null
                  : () => _refreshCurrentTab(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Obx(
                  () => Row(
                children: [
                  Expanded(
                    child: _buildTabButton('Transaksi', Icons.receipt_long, 0),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'Keuangan',
                      Icons.account_balance_wallet,
                      1,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton('Ringkasan', Icons.analytics, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() => _buildTabContent()),
    );
  }

  void _calculateCombinedStats(_) {
    // Calculate transaction profit
    double transactionProfit = 0.0;
    for (var transaction in controller.transactions) {
      if (transaction.paymentStatus == 'paid') {
        transactionProfit += transaction.profit;
      }
    }
    totalTransactionProfit.value = transactionProfit;

    // Calculate additional income and expenses
    double additionalIncome = 0.0;
    double expenses = 0.0;

    for (var record in incomeExpenseController.allRecords) {
      if (record.type == 'income') {
        additionalIncome += record.amount;
      } else {
        expenses += record.amount;
      }
    }

    totalAdditionalIncome.value = additionalIncome;
    totalExpenses.value = expenses;

    // Calculate total revenue (laba transaksi + pendapatan income)
    totalRevenue.value =
        totalTransactionProfit.value + totalAdditionalIncome.value;

    // Calculate net profit
    netProfit.value = totalRevenue.value - totalExpenses.value;
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    final isSelected = selectedTabIndex.value == index;

    return GestureDetector(
      onTap: () => selectedTabIndex.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow:
          isSelected
              ? [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTabIndex.value) {
      case 0:
        return _buildTransactionTab();
      case 1:
        return _buildIncomeExpenseTab();
      case 2:
        return _buildSummaryTab();
      default:
        return _buildTransactionTab();
    }
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Revenue Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Pendapatan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Obx(
                        () => Text(
                      _formatCurrency(totalRevenue.value),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBreakdownRow(
                    'Laba Penjualan',
                    totalTransactionProfit.value,
                    Colors.blue,
                    Icons.shopping_cart,
                  ),
                  const SizedBox(height: 8),
                  _buildBreakdownRow(
                    'Pendapatan Lain',
                    totalAdditionalIncome.value,
                    Colors.green,
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Expenses and Net Profit
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_down,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Pengeluaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Obx(
                              () => Text(
                            _formatCurrency(totalExpenses.value),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                      () => Card(
                    color:
                    netProfit.value >= 0
                        ? Colors.purple.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color:
                                netProfit.value >= 0
                                    ? Colors.purple
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Laba Bersih',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(netProfit.value),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                              netProfit.value >= 0
                                  ? Colors.purple[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistics Cards
          const Text(
            'Statistik Detail',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow(
                    'Total Transaksi',
                    '${controller.transactions.length}',
                    Icons.receipt,
                    Colors.blue,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'Catatan Pendapatan',
                    '${incomeExpenseController.incomeRecords.length}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'Catatan Pengeluaran',
                    '${incomeExpenseController.expenseRecords.length}',
                    Icons.trending_down,
                    Colors.red,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'Total Catatan Keuangan',
                    '${incomeExpenseController.allRecords.length}',
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Performance Indicators
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indikator Kinerja',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final profitMargin =
                    totalRevenue.value > 0
                        ? (netProfit.value / totalRevenue.value) * 100
                        : 0.0;
                    final expenseRatio =
                    totalRevenue.value > 0
                        ? (totalExpenses.value / totalRevenue.value) * 100
                        : 0.0;

                    return Column(
                      children: [
                        _buildPerformanceIndicator(
                          'Margin Laba',
                          '${profitMargin.toStringAsFixed(1)}%',
                          profitMargin,
                          Icons.trending_up,
                        ),
                        const SizedBox(height: 12),
                        _buildPerformanceIndicator(
                          'Rasio Pengeluaran',
                          '${expenseRatio.toStringAsFixed(1)}%',
                          100 - expenseRatio,
                          Icons.pie_chart,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
      String label,
      double amount,
      Color color,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
      String label,
      String percentage,
      double value,
      IconData icon,
      ) {
    final color =
    value >= 70
        ? Colors.green
        : value >= 40
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              percentage,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (value / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildTransactionTab() {
    return Obx(() {
      if (controller.isLoading.value && controller.transactions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum ada transaksi',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/transaction'),
                icon: const Icon(Icons.add),
                label: const Text('Buat Transaksi Pertama'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchTransactions(),
        child: _buildGroupedTransactionList(),
      );
    });
  }

  Widget _buildGroupedTransactionList() {
    // Group transactions by date
    Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in controller.transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort keys (dates) in descending order
    List<String> sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String dateKey = sortedDates[index];
        List<Transaction> dayTransactions = groupedTransactions[dateKey]!;
        DateTime date = DateTime.parse(dateKey);

        // Calculate daily totals
        double dailyTotal = dayTransactions.fold(0, (sum, transaction) => sum + transaction.totalAmount);
        double dailyProfit = dayTransactions.fold(0, (sum, transaction) => sum + transaction.profit);
        double dailyPending = dayTransactions
            .where((t) => t.paymentStatus == 'pending')
            .fold(0, (sum, transaction) => sum + (transaction.totalAmount - transaction.amountPaid));
        int pendingCount = dayTransactions.where((t) => t.paymentStatus == 'pending').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: EdgeInsets.only(bottom: 8, top: index == 0 ? 0 : 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateHeader(date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${dayTransactions.length} transaksi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Rp ${_formatPrice(dailyTotal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 12,
                        ),
                      ),
                      // Show pending amount if any
                      if (dailyPending > 0) ...[
                        Text(
                          'Hutang: Rp ${_formatPrice(dailyPending)} ($pendingCount)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Transactions for this date
            ...dayTransactions.map((transaction) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSimpleTransactionCard(transaction),
                )
            ).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSimpleTransactionCard(Transaction transaction) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showTransactionDetail(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status Icon with enhanced visual for pending payments
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: transaction.paymentStatus == 'paid'
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: transaction.paymentStatus == 'pending' &&
                      transaction.amountPaid < transaction.totalAmount
                      ? Border.all(color: Colors.orange.shade300, width: 1.5)
                      : null,
                ),
                child: Icon(
                  transaction.paymentStatus == 'paid'
                      ? Icons.check_circle
                      : Icons.pending,
                  color: transaction.paymentStatus == 'paid'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  size: 16,
                ),
              ),

              const SizedBox(width: 12),

              // Transaction Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          transaction.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('HH:mm').format(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    if (transaction.customerName != null && transaction.customerName!.isNotEmpty) ...[
                      Text(
                        transaction.customerName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    Row(
                      children: [
                        Text(
                          '${transaction.items.length} item',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${_formatPrice(transaction.totalAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 14,
                              ),
                            ),
                            // Show remaining payment if pending
                            if (transaction.paymentStatus == 'pending' &&
                                transaction.amountPaid < transaction.totalAmount) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Kurang: Rp ${_formatPrice(transaction.totalAmount - transaction.amountPaid)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More Actions
              PopupMenuButton(
                icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('Detail', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    onTap: () => _showTransactionDetail(transaction),
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.receipt, size: 18),
                        SizedBox(width: 8),
                        Text('Struk', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    onTap: () => _showReceipt(transaction),
                  ),
                  if (transaction.paymentStatus == 'pending')
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.payment, size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Lunasi', style: TextStyle(color: Colors.green, fontSize: 13)),
                        ],
                      ),
                      onTap: () => _showPaymentDialog(transaction),
                    ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                    onTap: () => _confirmDeleteTransaction(transaction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hari Ini';
    } else if (dateOnly == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    }
  }

  Widget _buildIncomeExpenseTab() {
    return Obx(() {
      if (incomeExpenseController.isLoading.value &&
          incomeExpenseController.allRecords.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      // Show summary cards at top
      return Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pendapatan Lain',
                    incomeExpenseController.totalIncome.value,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pengeluaran Bisnis',
                    incomeExpenseController.totalExpense.value,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter tabs for income/expense
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    'Semua',
                    'all',
                    incomeExpenseController.filterType.value,
                        () => incomeExpenseController.filterType.value = 'all',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    'Pendapatan',
                    'income',
                    incomeExpenseController.filterType.value,
                        () => incomeExpenseController.filterType.value = 'income',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    'Pengeluaran',
                    'expense',
                    incomeExpenseController.filterType.value,
                        () => incomeExpenseController.filterType.value = 'expense',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Records List
          Expanded(
            child: Obx(() {
              final records = incomeExpenseController.filteredRecords;

              if (records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada catatan keuangan',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed:
                            () => incomeExpenseController.showFormDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Catatan'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => incomeExpenseController.fetchAllRecords(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _buildIncomeExpenseCard(record);
                  },
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(
      String title,
      double amount,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String value,
      String currentValue,
      VoidCallback onTap,
      ) {
    final isSelected = currentValue == value;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseCard(IncomeExpense record) {
    final isIncome = record.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.trending_up : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => incomeExpenseController.showFormDialog(record: record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isIncome ? 'Pendapatan Lain' : 'Pengeluaran Bisnis',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatCurrency(record.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          incomeExpenseController.getPaymentMethodDisplay(
                            record.paymentMethod,
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(record.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (record.notes != null && record.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.notes!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder:
                    (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                    onTap:
                        () => incomeExpenseController.showFormDialog(
                      record: record,
                    ),
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () => _confirmDeleteIncomeExpense(record),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshCurrentTab() {
    if (selectedTabIndex.value == 0) {
      controller.fetchTransactions();
    } else if (selectedTabIndex.value == 1) {
      incomeExpenseController.fetchAllRecords();
      incomeExpenseController.fetchStatistics();
    } else {
      // Refresh both for summary tab
      controller.fetchTransactions();
      incomeExpenseController.fetchAllRecords();
      incomeExpenseController.fetchStatistics();
    }
  }

  void _showTransactionDetail(Transaction transaction) {
    Get.to(() => TransactionDetail(transaction: transaction));
  }

  void _showFilterOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedTabIndex.value == 0
                  ? 'Filter Transaksi'
                  : selectedTabIndex.value == 1
                  ? 'Filter Keuangan'
                  : 'Filter Data',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Hari Ini'),
              onTap: () => _filterToday(),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Pilih Rentang Tanggal'),
              onTap: () => _showDateRangePicker(),
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Tampilkan Semua'),
              onTap: () => _clearFilter(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _filterToday() async {
    Get.back();
    if (selectedTabIndex.value == 0) {
      final service = Get.find<TransactionService>();
      final todayTransactions = await service.getTodayTransactions();
      controller.transactions.assignAll(todayTransactions);
    } else if (selectedTabIndex.value == 1) {
      final todayRecords =
      await incomeExpenseController.service.getTodayRecords();
      incomeExpenseController.allRecords.assignAll(todayRecords);
    } else {
      // Filter both for summary
      final service = Get.find<TransactionService>();
      final todayTransactions = await service.getTodayTransactions();
      controller.transactions.assignAll(todayTransactions);

      final todayRecords =
      await incomeExpenseController.service.getTodayRecords();
      incomeExpenseController.allRecords.assignAll(todayRecords);
    }
  }

  void _showDateRangePicker() {
    Get.back();
    Get.snackbar('Info', 'Date range picker akan diimplementasikan');
  }

  void _clearFilter() {
    Get.back();
    _refreshCurrentTab();
  }

  void _printTransaction(Transaction transaction) async {
    if (setController.printService.devices.isEmpty) {
      await _printService.startScan();
    }

    if (setController.printService.selectedDevice.value != null) {
      try {
        await setController.printTransaction(
          customerName: setController.storeName.value,
          customerLocation: setController.storeAddress.value,
          customerPhone: setController.storePhone.value,
          dateTime: DateTime.now().toString(),
          items: transaction.items,
          subtotal: 'Rp ${transaction.subtotal.toString()}',
          adminFee: 'Rp ${transaction.serviceFee.toString()}',
          total: 'Rp ${transaction.totalAmount.toStringAsFixed(0)}',
          payment: 'Rp ${transaction.paymentMethod.toString()}',
          change: 'Rp ${transaction.changeAmount.toString()}',
          status: 'LUNAS',
          trxCode: 'TRX-${transaction.id}',
          footerNote:
          setController.receiptFooterNote.value.isNotEmpty
              ? setController.receiptFooterNote.value
              : "",
        );
      } catch (e) {
        Get.snackbar('Error', e.toString());
      }
    } else {
      Get.snackbar('Error', 'Tidak ditemukan printer Bluetooth');
    }
  }

  void _confirmDeleteTransaction(Transaction transaction) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText:
      'Hapus transaksi ${transaction.id}?\nStok produk akan dikembalikan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await controller.deleteTransaction(transaction.id);
      },
    );
  }

  void _confirmDeleteIncomeExpense(IncomeExpense record) {
    final type = record.type == 'income' ? 'pendapatan' : 'pengeluaran';
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText:
      'Hapus catatan $type sebesar ${_formatCurrency(record.amount)}?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await incomeExpenseController.deleteRecord(record.id);
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _showReceipt(Transaction transaction) {
    Get.toNamed(
      '/receipt',
      arguments: {
        'transaction': transaction,
        'customerName': 'Alvin',
        'phoneNumber': '08573671088',
      },
    );
  }

  void _showPaymentDialog(Transaction transaction) {
    final remainingAmount = transaction.totalAmount - transaction.amountPaid;
    final paymentController = TextEditingController(
      text: remainingAmount.toString(),
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: primaryColor),
            const SizedBox(width: 12),
            const Text('Lunasi Pembayaran'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Transaksi: ${transaction.id}'),
            const SizedBox(height: 8),
            Text('Total: ${_formatCurrency(transaction.totalAmount)}'),
            Text('Sudah Dibayar: ${_formatCurrency(transaction.amountPaid)}'),
            Text(
              'Sisa: ${_formatCurrency(remainingAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Pembayaran',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final paymentAmount =
                  double.tryParse(paymentController.text) ?? 0;
              if (paymentAmount <= 0) {
                Get.snackbar('Error', 'Masukkan jumlah pembayaran yang valid');
                return;
              }

              Get.back();
              await _completePayment(transaction, paymentAmount);
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }

  Future<void> _completePayment(
      Transaction transaction,
      double additionalPayment,
      ) async {
    try {
      final service = Get.find<TransactionService>();
      final newTotalPaid = transaction.amountPaid + additionalPayment;
      final newStatus =
      newTotalPaid >= transaction.totalAmount ? 'paid' : 'pending';
      final newChangeAmount =
      newStatus == 'paid' ? newTotalPaid - transaction.totalAmount : 0.0;

      await service.updateTransactionPayment(
        transactionId: transaction.id,
        paymentMethod: transaction.paymentMethod,
        amountPaid: newTotalPaid,
        changeAmount: newChangeAmount,
        paymentStatus: newStatus,
      );
      if (transaction.customerName != null && additionalPayment > 0) {
        try {
          // Find customer by name
          await customerController.fetchCustomers();
          final customer = customerController.customers.firstWhereOrNull(
                (c) => c.name == transaction.customerName,
          );

          if (customer != null) {
            // Add payment record to customer transactions
            await customerController.addPayment(
              customer.id,
              amount: additionalPayment,
              paymentMethod: transaction.paymentMethod,
              notes: 'Pelunasan Transaksi: ${transaction.id}',
            );
          }
        } catch (e) {
          print('Error updating customer balance: $e');
        }
      }
      await controller.fetchTransactions();

      Get.snackbar(
        'Berhasil',
        newStatus == 'paid'
            ? 'Pembayaran berhasil dilunasi'
            : 'Pembayaran berhasil diperbarui',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui pembayaran: $e');
    }
  }
}
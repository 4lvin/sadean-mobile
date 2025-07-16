import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sadean/src/config/assets.dart';
import 'package:sadean/src/view/transaction/transaction_view.dart';

import '../../config/theme.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/income_expense_controller.dart'; // Add this import
import '../../models/transaction_model.dart';
import '../../routers/constant.dart';

class TransactionIndex extends StatelessWidget {
  final TransactionController controller = Get.put(TransactionController());
  final IncomeExpenseController incomeExpenseController = Get.put(IncomeExpenseController()); // Add this

  TransactionIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Image.asset(logoSamping, scale: 5),
                  const Spacer(),
                  // Container(
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.grey.withOpacity(0.1),
                  //         spreadRadius: 1,
                  //         blurRadius: 3,
                  //         offset: const Offset(0, 1),
                  //       ),
                  //     ],
                  //   ),
                  //   padding: const EdgeInsets.all(8),
                  //   // child: Icon(
                  //   //   Icons.notifications_none_rounded,
                  //   //   color: primaryColor,
                  //   // ),
                  // ),
                ],
              ),
            ),

            // Main Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.trending_down,
                          title: 'Pengeluaran',
                          color: Colors.red.withOpacity(0.9),
                          textColor: Colors.white,
                          onTap: () => _showExpenseForm(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.trending_up,
                          title: 'Pendapatan',
                          color: Colors.green.withOpacity(0.9),
                          textColor: Colors.white,
                          onTap: () => _showIncomeForm(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNewOrderCard(),
                ],
              ),
            ),

            // Cart Statistics
            Obx(() => controller.cartItems.isNotEmpty
                ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KERANJANG AKTIF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart, color: primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${controller.cartItemCount.value} item dalam keranjang',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Total: Rp ${controller.formatPrice(controller.cartTotal.value)}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.to(() => TransactionView()),
                            child: const Text('Lanjut'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink()),

            // Recent Transactions
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRANSAKSI TERBARU',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildRecentTransactions(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show expense form
  void _showExpenseForm() {
    incomeExpenseController.resetForm();
    incomeExpenseController.selectedType.value = 'expense';
    incomeExpenseController.useCustomDateTime.value = false; // Default to current date
    _showIncomeExpenseDialog();
  }

  // Method to show income form
  void _showIncomeForm() {
    incomeExpenseController.resetForm();
    incomeExpenseController.selectedType.value = 'income';
    incomeExpenseController.useCustomDateTime.value = false; // Default to current date
    _showIncomeExpenseDialog();
  }

  // Custom dialog for income/expense
  void _showIncomeExpenseDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                      'Tambah ${incomeExpenseController.selectedType.value == 'income' ? 'Pendapatan' : 'Pengeluaran'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date & Time Toggle (Default to current date)
                Obx(() => SwitchListTile(
                  title: const Text('Atur Tanggal & Waktu'),
                  subtitle: Text(
                    incomeExpenseController.useCustomDateTime.value
                        ? DateFormat('dd MMM yyyy, HH:mm').format(incomeExpenseController.selectedDateTime.value)
                        : 'Gunakan waktu saat ini',
                    style: TextStyle(
                      color: incomeExpenseController.useCustomDateTime.value ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  value: incomeExpenseController.useCustomDateTime.value,
                  onChanged: (value) => incomeExpenseController.useCustomDateTime.value = value,
                  contentPadding: EdgeInsets.zero,
                )),

                // Date & Time Pickers
                Obx(() => incomeExpenseController.useCustomDateTime.value
                    ? Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(incomeExpenseController.selectedDateTime.value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectTime(),
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              DateFormat('HH:mm').format(incomeExpenseController.selectedDateTime.value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : const SizedBox.shrink()
                ),

                const SizedBox(height: 16),

                // Amount
                const Text(
                  'Nominal',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: incomeExpenseController.amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                ),

                const SizedBox(height: 16),

                // Payment Method
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: incomeExpenseController.selectedPaymentMethod.value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                    DropdownMenuItem(value: 'card', child: Text('Kartu')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (value) => incomeExpenseController.selectedPaymentMethod.value = value!,
                )),

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: incomeExpenseController.notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Tambahkan catatan...',
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: incomeExpenseController.isLoading.value
                            ? null
                            : () => incomeExpenseController.saveRecord(),
                        child: incomeExpenseController.isLoading.value
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Simpan'),
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: incomeExpenseController.selectedDateTime.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      incomeExpenseController.selectedDateTime.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        incomeExpenseController.selectedDateTime.value.hour,
        incomeExpenseController.selectedDateTime.value.minute,
      );
    }
  }

  // Select time
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.fromDateTime(incomeExpenseController.selectedDateTime.value),
    );

    if (picked != null) {
      incomeExpenseController.selectedDateTime.value = DateTime(
        incomeExpenseController.selectedDateTime.value.year,
        incomeExpenseController.selectedDateTime.value.month,
        incomeExpenseController.selectedDateTime.value.day,
        picked.hour,
        picked.minute,
      );
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: textColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewOrderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => TransactionView()),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Colors.blue[800],
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buat transaksi baru dengan produk',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final historyController = Get.find<HistoryController>();

    return Obx(() {
      if (historyController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (historyController.transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum ada transaksi',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      // Show only recent 5 transactions
      final recentTransactions = historyController.transactions.take(5).toList();

      return ListView.builder(
        itemCount: recentTransactions.length,
        itemBuilder: (context, index) {
          final transaction = recentTransactions[index];
          return _buildTransactionCard(transaction);
        },
      );
    });
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final now = DateTime.now();
    final transactionDate = transaction.date;
    final formattedDate = DateFormat('dd MMM, HH:mm').format(transactionDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // onTap: () => Get.to(() => TransactionDetailHistoryView(transaction: transaction)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${transaction.items.length} item',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Rp ${controller.formatPrice(transaction.totalAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
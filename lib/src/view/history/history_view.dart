import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/controllers/setting_controller.dart';
import 'package:sadean/src/view/history/history_detail.dart';
import '../../controllers/history_controller.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../service/thermal_print_service.dart';
import '../../service/transaction_service.dart';
import '../transaction/transaction_detail.dart';

class HistoryView extends StatelessWidget {
  final HistoryController controller = Get.find<HistoryController>();
  final BluetoothPrintService _printService = BluetoothPrintService();
  final SettingsController setController = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(),
          ),
          Obx(
            () => IconButton(
              icon:
                  controller.isLoading.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.refresh),
              onPressed:
                  controller.isLoading.value
                      ? null
                      : () => controller.fetchTransactions(),
            ),
          ),
        ],
      ),
      body: Obx(() {
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.transactions.length,
            itemBuilder: (context, index) {
              final transaction = controller.transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _showTransactionDetail(transaction),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatDate(transaction.date),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                PopupMenuButton(
                                  itemBuilder:
                                      (context) => [
                                        PopupMenuItem(
                                          child: const Row(
                                            children: [
                                              Icon(Icons.visibility, size: 20),
                                              SizedBox(width: 8),
                                              Text('Detail'),
                                            ],
                                          ),
                                          onTap:
                                              () => _showTransactionDetail(
                                                transaction,
                                              ),
                                        ),
                                        PopupMenuItem(
                                          child: const Row(
                                            children: [
                                              Icon(Icons.receipt, size: 20),
                                              SizedBox(width: 8),
                                              Text('Lihat Struk'),
                                            ],
                                          ),
                                          onTap:
                                              () => _showReceipt(transaction),
                                        ),
                                        PopupMenuItem(
                                          child: const Row(
                                            children: [
                                              Icon(Icons.print, size: 20),
                                              SizedBox(width: 8),
                                              Text('Cetak'),
                                            ],
                                          ),
                                          onTap:
                                              () => _printTransaction(
                                                transaction,
                                              ),
                                        ),
                                        PopupMenuItem(
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap:
                                              () => _confirmDelete(transaction),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${transaction.items.length} item',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getItemsSummary(transaction),
                          style: TextStyle(color: Colors.grey[800]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Rp ${_formatPrice(transaction.totalAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Laba',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Rp ${_formatPrice(transaction.profit)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
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
            const Text(
              'Filter Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final service = Get.find<TransactionService>();
    final todayTransactions = await service.getTodayTransactions();
    controller.transactions.assignAll(todayTransactions);
  }

  void _showDateRangePicker() {
    Get.back();
    // Implement date range picker
    Get.snackbar('Info', 'Date range picker akan diimplementasikan');
  }

  void _clearFilter() {
    Get.back();
    controller.fetchTransactions();
  }

  void _printTransaction(Transaction transaction) async {
    if (setController.printers.isEmpty) {
      await _printService.startScan();
    }

    if (setController.selectedPrinterDevice.value != null) {
      // _printService.selectDevice(_printService.devices.first);

      try {
        await setController.printTransaction(
          customerName: "SADEAN",
          customerLocation: "PANDAAN",
          customerPhone: "085736710089",
          dateTime: DateTime.now().toString(),
          items: transaction.items,
          subtotal: 'Rp ${transaction.subtotal.toString()}',
          adminFee: 'Rp ${transaction.serviceFee.toString()}',
          total: 'Rp ${transaction.totalAmount.toStringAsFixed(0)}',
          payment: 'Rp ${transaction.paymentMethod.toString()}',
          change: 'Rp ${transaction.changeAmount.toString()}',
          status: 'LUNAS',
          trxCode: 'TRX-${transaction.id}',
        );

        // Get.snackbar(
        //   'Info',
        //   'Struk transaksi ${transaction.id} berhasil dicetak',
        // );
      } catch (e) {
        Get.snackbar('Error', e.toString());
      }
    } else {
      Get.snackbar('Error', 'Tidak ditemukan printer Bluetooth');
    }
  }

  void _confirmDelete(Transaction transaction) {
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

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _getItemsSummary(Transaction transaction) {
    return transaction.items.map((item) => item.productName).join(', ');
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showReceipt(Transaction transaction) {
    Get.toNamed('/receipt', arguments: {
      'transaction': transaction,
      'customerName': 'Alvin',
      'phoneNumber': '08573671088',
    });
  }
}

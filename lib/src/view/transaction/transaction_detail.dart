import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/history_controller.dart';
import '../../models/transaction_model.dart';
import '../../service/transaction_service.dart';

class TransactionDetail extends StatelessWidget {
  final Transaction transaction;

  TransactionDetail({super.key, required this.transaction});
  final HistoryController controller = Get.find<HistoryController>();
  final CustomerController customerController = Get.put(CustomerController());
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with back button
          Container(
            color: primaryColor.withOpacity(0.8),
            padding: const EdgeInsets.only(top: 40, bottom: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Transaksi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            transaction.id,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          switch (value) {
                            case 'delete':
                              _confirmDelete(context);
                              break;
                            case 'payment':
                              if (transaction.paymentStatus == 'pending') {
                                _showPaymentDialog(context);
                              }
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          if (transaction.paymentStatus == 'pending')
                            const PopupMenuItem(
                              value: 'payment',
                              child: Row(
                                children: [
                                  Icon(Icons.payment, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Lunasi Pembayaran', style: TextStyle(color: Colors.green)),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Informasi Transaksi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('ID Transaksi', transaction.id),
                          if (transaction.customerName != null && transaction.customerName!.isNotEmpty)
                            _buildInfoRow('Pelanggan', transaction.customerName!),
                          _buildInfoRow('Tanggal', _formatDate(transaction.date)),
                          _buildInfoRow('Total Item', '${transaction.items.length} item'),
                          const Divider(height: 20),
                          _buildInfoRow('Subtotal', currencyFormat.format(transaction.subtotal)),
                          if (transaction.serviceFee! > 0)
                            _buildInfoRow('Biaya Admin', currencyFormat.format(transaction.serviceFee)),
                          if (transaction.tax != null && transaction.tax! > 0)
                            _buildInfoRow('Pajak', currencyFormat.format(transaction.tax!)),
                          if (transaction.shippingCost != null && transaction.shippingCost! > 0)
                            _buildInfoRow('Ongkir', currencyFormat.format(transaction.shippingCost!)),
                          const Divider(height: 20),
                          _buildInfoRow('Total Bayar', currencyFormat.format(transaction.totalAmount),
                              valueColor: Colors.blue[700], isBold: true),
                          _buildInfoRow('Modal', currencyFormat.format(transaction.costAmount)),
                          _buildInfoRow('Laba', currencyFormat.format(transaction.profit),
                              valueColor: Colors.green, isBold: true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Status Card - Enhanced for pending payments
                  if (transaction.paymentStatus == 'pending' || transaction.amountPaid > 0)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  transaction.paymentStatus == 'paid'
                                      ? Icons.check_circle
                                      : Icons.pending_actions,
                                  color: transaction.paymentStatus == 'paid'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status Pembayaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: transaction.paymentStatus == 'paid'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildInfoRow(
                              'Sudah Dibayar',
                              currencyFormat.format(transaction.amountPaid),
                              valueColor: Colors.blue[700],
                              isBold: true,
                            ),

                            if (transaction.paymentStatus == 'pending' &&
                                transaction.amountPaid < transaction.totalAmount) ...[
                              _buildInfoRow(
                                'Kurang Bayar',
                                currencyFormat.format(transaction.totalAmount - transaction.amountPaid),
                                valueColor: Colors.red[700],
                                isBold: true,
                              ),
                              const SizedBox(height: 12),

                              // Payment progress bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Progress Pembayaran',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${((transaction.amountPaid / transaction.totalAmount) * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: transaction.amountPaid / transaction.totalAmount,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      transaction.amountPaid >= transaction.totalAmount
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    minHeight: 8,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Payment action button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showPaymentDialog(context),
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Lunasi Pembayaran'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (transaction.paymentStatus == 'paid') ...[
                              _buildInfoRow(
                                'Kembalian',
                                currencyFormat.format(transaction.changeAmount),
                                valueColor: Colors.green[700],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pembayaran Lunas',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Items list
                  const Text(
                    'Detail Item',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transaction.items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = transaction.items[index];
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${currencyFormat.format(item.unitPrice)} x ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(item.quantity * item.unitPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Laba: ${currencyFormat.format((item.unitPrice - item.costPrice) * item.quantity)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Receipt Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showReceipt,
                      icon: const Icon(Icons.receipt),
                      label: const Text('Lihat Struk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (transaction.paymentStatus.toLowerCase()) {
      case 'paid':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'LUNAS';
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusText = 'BELUM LUNAS';
        icon = Icons.pending;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusText = 'TIDAK DIKETAHUI';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm').format(date);
  }

  void _showReceipt() {
    Get.toNamed('/receipt', arguments: {
      'transaction': transaction,
      'customerName': 'Customer',
      'phoneNumber': '08573671088',
    });
  }

  void _showPaymentDialog(BuildContext context) {
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
            Text('Total: ${currencyFormat.format(transaction.totalAmount)}'),
            Text('Sudah Dibayar: ${currencyFormat.format(transaction.amountPaid)}'),
            Text(
              'Sisa: ${currencyFormat.format(remainingAmount)}',
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

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus transaksi ${transaction.id}?\nStok produk akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog
              await _deleteTransaction();
              Get.back(); // Return to history
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    try {
      final historyController = Get.find<HistoryController>();
      await historyController.deleteTransaction(transaction.id);
      Get.snackbar('Sukses', 'Transaksi berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus transaksi: $e');
    }
  }
}
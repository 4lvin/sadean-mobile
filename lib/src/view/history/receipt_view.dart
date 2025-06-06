import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../controllers/setting_controller.dart';
import '../../models/transaction_model.dart';
import '../../service/thermal_print_service.dart';

class ReceiptView extends StatelessWidget {
  final Transaction transaction;
  final String customerName;
  final String phoneNumber;

   ReceiptView({
    super.key,
    required this.transaction,
    this.customerName = "Alvin",
    this.phoneNumber = "08573671088",
  });

  final BluetoothPrintService _printService = BluetoothPrintService();
  final SettingsController setController = Get.find<SettingsController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Struk'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Status Printer
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Tidak ada',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Printer',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Receipt Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Lihat Contoh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Receipt Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header - Store Name & Customer Info
                          Text(
                            transaction.customerName ?? customerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pandaan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Divider line
                          _buildDividerLine(),

                          const SizedBox(height: 8),

                          // Transaction Date & Time
                          Text(
                            'Tanggal: ${_formatDateTime(transaction.date)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),

                          const SizedBox(height: 8),
                          _buildDividerLine(),
                          const SizedBox(height: 16),

                          // Items Section
                          ...transaction.items.map((item) => _buildReceiptItem(item)),

                          const SizedBox(height: 8),
                          _buildDividerLine(),
                          const SizedBox(height: 12),

                          // Totals Section
                          _buildTotalRow('Subtotal', transaction.calculatedSubtotal),

                          // Discount (if any)
                          if (transaction.discount != null && transaction.discount! > 0)
                            _buildTotalRow(
                              'Diskon',
                              -transaction.discount!,
                              isNegative: true,
                            ),

                          // Service Fee (if any)
                          if (transaction.serviceFee != null && transaction.serviceFee! > 0)
                            _buildTotalRow('Biaya Admin', transaction.serviceFee!),

                          // Shipping Cost (if any)
                          if (transaction.shippingCost != null && transaction.shippingCost! > 0)
                            _buildTotalRow('Ongkos Kirim', transaction.shippingCost!),

                          // Tax (if any)
                          if (transaction.tax != null && transaction.tax! > 0)
                            _buildTotalRow('Pajak', transaction.tax!),

                          const SizedBox(height: 8),

                          // Final Total
                          _buildTotalRow(
                            'Total Akhir',
                            transaction.totalAmount,
                            isBold: true,
                            fontSize: 18,
                          ),

                          const SizedBox(height: 8),
                          _buildDividerLine(),
                          const SizedBox(height: 8),

                          // Payment Information
                          _buildPaymentSection(),

                          const SizedBox(height: 16),

                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor()),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Payment Method
                          Text(
                            _getPaymentMethodText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Transaction ID
                          Text(
                            transaction.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),

                          // Date & Time at bottom
                          Text(
                            _formatDateTimeBottom(transaction.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),

                          // Notes (if any)
                          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDividerLine(),
                            const SizedBox(height: 8),
                            Text(
                              'Catatan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              transaction.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Print Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPrintDialog(),
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: primaryColor),
                        foregroundColor: primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Share Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareReceipt(),
                      icon: const Icon(Icons.share),
                      label: const Text('Bagikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildReceiptItem(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name and total
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.productName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${item.quantity}pcs',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatCurrency(item.unitPrice),
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Text(
                  _formatCurrency(item.totalPrice),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {
    bool isBold = false,
    bool isNegative = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${_formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      children: [
        // Payment Amount
        _buildTotalRow(
          'Pembayaran',
          transaction.amountPaid,
          isBold: true,
          fontSize: 16,
        ),

        // Change Amount (if any)
        if (transaction.changeAmount > 0)
          _buildTotalRow(
            'Kembali',
            transaction.changeAmount,
            isBold: true,
            fontSize: 16,
          ),

        // Exact payment case
        if (transaction.changeAmount == 0 && transaction.amountPaid == transaction.totalAmount)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kembali',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDividerLine() {
    return Row(
      children: List.generate(
        50,
            (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.grey[400] : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy HH:mm', 'id_ID').format(date);
  }

  String _formatDateTimeBottom(DateTime date) {
    return DateFormat('d MMM yyyy HH:mm', 'id_ID').format(date);
  }

  Color _getStatusColor() {
    switch (transaction.paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (transaction.paymentStatus.toLowerCase()) {
      case 'paid':
        return 'LUNAS';
      case 'pending':
        return 'MENUNGGU';
      case 'cancelled':
        return 'DIBATALKAN';
      default:
        return 'TIDAK DIKETAHUI';
    }
  }

  String _getPaymentMethodText() {
    switch (transaction.paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'qris':
        return 'QRIS';
      case 'transfer':
        return 'Transfer Bank';
      case 'card':
        return 'Kartu';
      default:
        return transaction.paymentMethod.toUpperCase();
    }
  }

  void _showPrintDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.print, color: Colors.blue),
            SizedBox(width: 12),
            Text('Cetak Struk'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Printer: Tidak ada',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text('Silakan hubungkan printer Bluetooth untuk mencetak struk.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atur printer di menu Pengaturan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _printTransaction(transaction);
            },
            child: const Text('Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _shareReceipt() {
    // Simulasi berbagi struk
    final receiptText = _generateReceiptText();

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: receiptText));

    Get.snackbar(
      'Berhasil',
      'Detail struk telah disalin ke clipboard',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  String _generateReceiptText() {
    String receipt = '''
${transaction.customerName ?? customerName}
Pandaan
$phoneNumber

Tanggal: ${_formatDateTime(transaction.date)}
${'-' * 32}

''';

    // Items
    for (var item in transaction.items) {
      receipt += '${item.productName.toUpperCase()}\n';
      receipt += '${item.quantity}pcs x ${_formatCurrency(item.unitPrice)} = ${_formatCurrency(item.totalPrice)}\n\n';
    }

    receipt += '''${'-' * 32}
Subtotal: ${_formatCurrency(transaction.calculatedSubtotal)}
''';

    // Adjustments
    if (transaction.discount != null && transaction.discount! > 0) {
      receipt += 'Diskon: -${_formatCurrency(transaction.discount!)}\n';
    }

    if (transaction.serviceFee != null && transaction.serviceFee! > 0) {
      receipt += 'Biaya Admin: ${_formatCurrency(transaction.serviceFee!)}\n';
    }

    if (transaction.shippingCost != null && transaction.shippingCost! > 0) {
      receipt += 'Ongkos Kirim: ${_formatCurrency(transaction.shippingCost!)}\n';
    }

    if (transaction.tax != null && transaction.tax! > 0) {
      receipt += 'Pajak: ${_formatCurrency(transaction.tax!)}\n';
    }

    receipt += '''
Total Akhir: ${_formatCurrency(transaction.totalAmount)}
${'-' * 32}
Pembayaran (${_getPaymentMethodText()}): ${_formatCurrency(transaction.amountPaid)}
''';

    if (transaction.changeAmount > 0) {
      receipt += 'Kembali: ${_formatCurrency(transaction.changeAmount)}\n';
    } else if (transaction.changeAmount == 0 && transaction.amountPaid == transaction.totalAmount) {
      receipt += 'Kembali: Pas\n';
    }

    receipt += '''
${_getStatusText()}

${transaction.id}
${_formatDateTimeBottom(transaction.date)}
''';

    if (transaction.notes != null && transaction.notes!.isNotEmpty) {
      receipt += '''
Catatan: ${transaction.notes}
''';
    }

    return receipt;
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
}
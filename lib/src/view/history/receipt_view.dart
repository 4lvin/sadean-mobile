import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../models/transaction_model.dart';

class ReceiptView extends StatelessWidget {
  final Transaction transaction;
  final String customerName;
  final String phoneNumber;

  const ReceiptView({
    super.key,
    required this.transaction,
    this.customerName = "Alvin",
    this.phoneNumber = "08573671088",
  });

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
                            customerName,
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

                          if (transaction.discount != null && transaction.discount! > 0)
                            _buildTotalRow('Layanan', transaction.serviceFee ?? 0),

                          const SizedBox(height: 8),

                          // Final Total
                          _buildTotalRow(
                            'Total Akhir',
                            transaction.totalAmount,
                            isBold: true,
                            fontSize: 18,
                          ),

                          _buildTotalRow(
                            'Pembayaran',
                            _calculatePayment(),
                            isBold: true,
                            fontSize: 16,
                          ),

                          _buildTotalRow(
                            'Kembali',
                            _calculateChange(),
                            isBold: true,
                            fontSize: 16,
                          ),

                          const SizedBox(height: 16),

                          // Status
                          Text(
                            'LUNAS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
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
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
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
      symbol: '',
      decimalDigits: 2,
    ).format(amount).replaceAll(',00', ',00');
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy HH.mm', 'id_ID').format(date);
  }

  String _formatDateTimeBottom(DateTime date) {
    return DateFormat('d MMM yyyy HH.mm', 'id_ID').format(date);
  }

  double _calculatePayment() {
    // Simulasi pembayaran (biasanya lebih besar atau sama dengan total)
    return transaction.totalAmount + 1000; // Contoh: bayar lebih Rp 1000
  }

  double _calculateChange() {
    return _calculatePayment() - transaction.totalAmount;
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
              Get.toNamed('/settings');
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
$customerName
Pandaan
$phoneNumber

Tanggal: ${_formatDateTime(transaction.date)}
${'-' * 32}

''';

    for (var item in transaction.items) {
      receipt += '${item.productName.toUpperCase()}\n';
      receipt += '${item.quantity}pcs x ${_formatCurrency(item.unitPrice)} = ${_formatCurrency(item.totalPrice)}\n\n';
    }

    receipt += '''${'-' * 32}
Subtotal: ${_formatCurrency(transaction.calculatedSubtotal)}
''';

    if (transaction.serviceFee != null && transaction.serviceFee! > 0) {
      receipt += 'Layanan: ${_formatCurrency(transaction.serviceFee!)}\n';
    }

    receipt += '''
Total Akhir: ${_formatCurrency(transaction.totalAmount)}
Pembayaran: ${_formatCurrency(_calculatePayment())}
Kembali: ${_formatCurrency(_calculateChange())}

LUNAS

${transaction.id}
${_formatDateTimeBottom(transaction.date)}
''';

    return receipt;
  }
}
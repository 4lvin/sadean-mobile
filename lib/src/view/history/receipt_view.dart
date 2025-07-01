import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final GlobalKey _receiptKey = GlobalKey();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showPrinterSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Printer Status Bar
          _buildPrinterStatusBar(),

          // Receipt Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Pratinjau Struk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Receipt Card
                  Container(
                    key: _receiptKey, // Add this key
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
                          ...transaction.items.map(
                                (item) => _buildReceiptItem(item),
                          ),

                          const SizedBox(height: 8),
                          _buildDividerLine(),
                          const SizedBox(height: 12),

                          // Totals Section
                          _buildTotalRow(
                            'Subtotal',
                            transaction.calculatedSubtotal,
                          ),

                          // Discount (if any)
                          if (transaction.discount != null &&
                              transaction.discount! > 0)
                            _buildTotalRow(
                              'Diskon',
                              -transaction.discount!,
                              isNegative: true,
                            ),

                          // Service Fee (if any)
                          if (transaction.serviceFee != null &&
                              transaction.serviceFee! > 0)
                            _buildTotalRow(
                              'Biaya Admin',
                              transaction.serviceFee!,
                            ),

                          // Shipping Cost (if any)
                          if (transaction.shippingCost != null &&
                              transaction.shippingCost! > 0)
                            _buildTotalRow(
                              'Ongkos Kirim',
                              transaction.shippingCost!,
                            ),

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                          if (transaction.notes != null &&
                              transaction.notes!.isNotEmpty) ...[
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
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  void _shareReceipt() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Bagikan Struk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Pilih format berbagi',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Share format options
            Row(
              children: [
                // Share as Image
                Expanded(
                  child: _buildShareFormatOption(
                    icon: Icons.image,
                    label: 'Gambar',
                    subtitle: 'Bagikan sebagai foto',
                    color: Colors.purple,
                    onTap: () => _shareAsImage(),
                  ),
                ),
                // const SizedBox(width: 12),
                // // Share as Text
                // Expanded(
                //   child: _buildShareFormatOption(
                //     icon: Icons.text_fields,
                //     label: 'Teks',
                //     subtitle: 'Bagikan sebagai teks',
                //     color: Colors.blue,
                //     onTap: () => _shareAsText(),
                //   ),
                // ),
              ],
            ),

            const SizedBox(height: 20),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareFormatOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// Share as image method
  void _shareAsImage() async {
    Get.back(); // Close bottom sheet

    // Show loading
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Membuat gambar struk...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Capture widget as image
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        Get.back(); // Close loading
        _showError('Gagal mengambil gambar struk');
        return;
      }

      // Convert to image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/struk_${transaction.id}.png').create();
      await file.writeAsBytes(pngBytes);

      Get.back(); // Close loading

      // Show share options for image
      _showImageShareOptions(file.path);

    } catch (e) {
      Get.back(); // Close loading
      _showError('Gagal membuat gambar: $e');
    }
  }

// Show image share options
  void _showImageShareOptions(String imagePath) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Bagikan Gambar Struk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),

            // Share options for image
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // WhatsApp
                _buildShareOption(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: () => _shareImageToWhatsApp(imagePath),
                ),

                // General Share
                _buildShareOption(
                  icon: Icons.share,
                  label: 'Lainnya',
                  color: Colors.blue,
                  onTap: () => _shareImageGeneral(imagePath),
                ),

                // Save to Gallery
                _buildShareOption(
                  icon: Icons.download,
                  label: 'Simpan',
                  color: Colors.purple,
                  onTap: () => _saveImageToGallery(imagePath),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

// Share image to WhatsApp
  void _shareImageToWhatsApp(String imagePath) async {
    Get.back(); // Close bottom sheet

    try {
      final result = await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Struk Transaksi - ${transaction.id}',
      );

      if (result.status == ShareResultStatus.success) {
        _showSuccess('Gambar berhasil dibagikan');
      }
    } catch (e) {
      _showError('Gagal membagikan gambar: $e');
    }
  }

// Share image via general share
  void _shareImageGeneral(String imagePath) async {
    Get.back(); // Close bottom sheet

    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Struk Transaksi - ${transaction.id}\n\n'
            'Customer: ${transaction.customerName ?? customerName}\n'
            'Total: ${_formatCurrency(transaction.totalAmount)}\n'
            'Tanggal: ${_formatDateTime(transaction.date)}',
        subject: 'Struk Transaksi - ${transaction.id}',
      );
    } catch (e) {
      _showError('Gagal membagikan gambar: $e');
    }
  }

// Save image to gallery
  void _saveImageToGallery(String imagePath) async {
    Get.back(); // Close bottom sheet

    try {
      // Copy to Downloads or Pictures directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final newPath = '${directory.path}/struk_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(imagePath).copy(newPath);

        _showSuccess('Gambar disimpan ke galeri');
      } else {
        _showError('Gagal mengakses penyimpanan');
      }
    } catch (e) {
      _showError('Gagal menyimpan gambar: $e');
    }
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

// Helper methods for feedback
  void _showSuccess(String message) {
    Get.snackbar(
      'Berhasil',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error_outline, color: Colors.red),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  Widget _buildPrinterStatusBar() {
    return Obx(() => Container(
      color: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPrinterStatusBackgroundColor(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getPrinterStatusBorderColor()),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (setController.isConnecting.value)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                else
                  Icon(
                    _getPrinterStatusIcon(),
                    size: 16,
                    color: _getPrinterStatusIconColor(),
                  ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showPrinterQuickAction(Get.context!),
                  child: Text(
                    _getPrinterStatusText(),
                    style: TextStyle(
                      color: _getPrinterStatusTextColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Status Printer',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    ));
  }

  Widget _buildBottomActionButtons() {
    return Container(
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
              child: Obx(() => OutlinedButton.icon(
                onPressed: setController.isPrinting.value
                    ? null
                    : () => _handlePrintAction(),
                icon: setController.isPrinting.value
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.print),
                label: Text(setController.isPrinting.value ? 'Mencetak...' : 'Cetak'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: primaryColor),
                  foregroundColor: primaryColor,
                ),
              )),
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
    );
  }

  // Printer status helper methods
  Color _getPrinterStatusBackgroundColor() {
    if (setController.isConnecting.value) return Colors.orange.shade50;
    if (setController.isConnected.value && setController.selectedPrinterDevice.value != null) return Colors.green.shade50;
    if (setController.selectedPrinterDevice.value != null && !setController.isConnected.value) return Colors.red.shade50;
    return Colors.grey.shade200;
  }

  Color _getPrinterStatusBorderColor() {
    if (setController.isConnecting.value) return Colors.orange;
    if (setController.isConnected.value && setController.selectedPrinterDevice.value != null) return Colors.green;
    if (setController.selectedPrinterDevice.value != null && !setController.isConnected.value) return Colors.red;
    return Colors.grey;
  }

  IconData _getPrinterStatusIcon() {
    if (setController.isConnected.value && setController.selectedPrinterDevice.value != null) return Icons.bluetooth_connected;
    if (setController.selectedPrinterDevice.value != null && !setController.isConnected.value) return Icons.bluetooth_disabled;
    return Icons.bluetooth;
  }

  Color _getPrinterStatusIconColor() {
    if (setController.isConnected.value && setController.selectedPrinterDevice.value != null) return Colors.green.shade700;
    if (setController.selectedPrinterDevice.value != null && !setController.isConnected.value) return Colors.red.shade700;
    return Colors.grey.shade700;
  }

  String _getPrinterStatusText() {
    if (setController.isConnecting.value) return 'Menghubungkan...';
    if (setController.isConnected.value && setController.selectedPrinterDevice.value != null) return 'Terhubung';
    if (setController.selectedPrinterDevice.value != null && !setController.isConnected.value) return 'Terputus';
    return 'Pilih Printer';
  }

  Color _getPrinterStatusTextColor() {
    if (setController.isConnecting.value) return Colors.orange.shade700;
    if (setController.isConnected.value && setController.selectedPrinterDevice.value != null) return Colors.green.shade700;
    if (setController.selectedPrinterDevice.value != null && !setController.isConnected.value) return Colors.red.shade700;
    return Colors.grey.shade700;
  }

  void _handlePrintAction() {
    if (setController.selectedPrinterDevice.value == null) {
      _showPrinterSelectionDialog();
    } else if (!setController.isConnected.value) {
      _showReconnectDialog();
    } else {
      _printTransaction(transaction);
    }
  }

  void _showPrinterQuickAction(BuildContext context) {
    if (setController.selectedPrinterDevice.value == null) {
      _showPrinterSelectionDialog();
    } else if (!setController.isConnected.value) {
      _showReconnectDialog();
    } else {
      _showPrinterMenu(context);
    }
  }

  void _showPrinterSelectionDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_searching, color: Colors.blue),
            SizedBox(width: 12),
            Text('Pilih Printer'),
          ],
        ),
        content: const Text('Belum ada printer yang dipilih. Pilih printer Bluetooth untuk mencetak struk.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Nanti')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showPrinterSettings(Get.context!);
            },
            child: const Text('Pilih Printer'),
          ),
        ],
      ),
    );
  }

  void _showReconnectDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.red),
            SizedBox(width: 12),
            Text('Printer Terputus'),
          ],
        ),
        content: Text('Koneksi ke printer ${setController.selectedPrinter.value} terputus. Hubungkan ulang?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await setController.connectSelectedPrinter();
            },
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );
  }

  void _showPrinterMenu(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Menu Printer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Cetak Struk'),
              subtitle: const Text('Cetak struk transaksi ini'),
              onTap: () {
                Get.back();
                _printTransaction(transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined, color: Colors.green),
              title: const Text('Test Print'),
              subtitle: const Text('Cetak halaman percobaan'),
              onTap: () {
                Get.back();
                setController.testPrint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth_disabled, color: Colors.orange),
              title: const Text('Putuskan Koneksi'),
              subtitle: const Text('Putuskan koneksi printer'),
              onTap: () {
                Get.back();
                setController.disconnectPrinter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Pengaturan Printer'),
              subtitle: const Text('Kelola pengaturan printer'),
              onTap: () {
                Get.back();
                _showPrinterSettings(context);
              },
            ),
          ],
        ),
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
              Text('${item.quantity}pcs', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              Text(
                _formatCurrency(item.unitPrice),
                style: const TextStyle(fontSize: 13),
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

  Widget _buildTotalRow(
      String label,
      double amount, {
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
        if (transaction.changeAmount == 0 &&
            transaction.amountPaid == transaction.totalAmount)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      receipt +=
      '${item.quantity}pcs x ${_formatCurrency(item.unitPrice)} = ${_formatCurrency(item.totalPrice)}\n\n';
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
      receipt +=
      'Ongkos Kirim: ${_formatCurrency(transaction.shippingCost!)}\n';
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
    } else if (transaction.changeAmount == 0 &&
        transaction.amountPaid == transaction.totalAmount) {
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
    try {
      // Ensure printer is selected and connected
      if (setController.selectedPrinterDevice.value == null) {
        Get.snackbar(
          'Error',
          'Silakan pilih printer terlebih dahulu',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Attempt to print
      await setController.printTransaction(
        customerName: "SADEAN",
        customerLocation: "PANDAAN",
        customerPhone: "085736710089",
        dateTime: transaction.date.toString(),
        items: transaction.items,
        subtotal: transaction.subtotal?.toString() ?? '0',
        adminFee: transaction.serviceFee?.toString() ?? '0',
        total: transaction.totalAmount.toStringAsFixed(0),
        payment: transaction.amountPaid.toString(),
        change: transaction.changeAmount.toString(),
        status: 'LUNAS',
        trxCode: transaction.id,
      );
    } catch (e) {
      print('Print error in receipt view: $e');
      Get.snackbar(
        'Error',
        'Gagal mencetak: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showPrinterSettings(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 12),
            Text("Pengaturan Printer"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current printer status
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getPrinterStatusIcon(),
                            color: _getPrinterStatusIconColor(),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Status: ${_getPrinterStatusText()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (setController.selectedPrinterDevice.value != null) ...[
                        SizedBox(height: 8),
                        Text('Printer: ${setController.selectedPrinter.value}'),
                        Text(
                          'MAC: ${setController.selectedPrinterDevice.value!.address ?? "Unknown"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  )),
                ),

                SizedBox(height: 16),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      setController.scanPrinters();
                      _showPrinterSelectionDialog2();
                    },
                    icon: Icon(Icons.bluetooth_searching),
                    label: Text('Pilih Printer Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: 8),

                if (setController.selectedPrinterDevice.value != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        setController.connectSelectedPrinter();
                      },
                      icon: Icon(Icons.bluetooth_connected),
                      label: Text('Hubungkan Ulang'),
                    ),
                  ),

                  SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        setController.testPrint();
                      },
                      icon: Icon(Icons.print_outlined),
                      label: Text('Test Print'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showPrinterSelectionDialog2() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bluetooth, color: Colors.blue),
            SizedBox(width: 12),
            Text("Pilih Printer"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() {
            if (setController.isLoading.value) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Mencari printer..."),
                  SizedBox(height: 8),
                  Text(
                    "Pastikan printer Bluetooth aktif",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              );
            }

            if (setController.printers.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text("Tidak ditemukan printer"),
                  SizedBox(height: 8),
                  Text(
                    "Pastikan printer Bluetooth aktif dan dalam jangkauan",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setController.scanPrinters(),
                    icon: Icon(Icons.refresh, size: 20),
                    label: Text("Scan Ulang"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: setController.printers.length,
              itemBuilder: (context, index) {
                final device = setController.printers[index];
                final isSelected = setController.selectedPrinter.value == (device.name ?? 'Unknown');

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.print,
                      color: isSelected ? Colors.blue : Colors.grey[600],
                    ),
                    title: Text(
                      device.name ?? 'Unknown Device',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    subtitle: Text(
                      'MAC: ${device.address ?? "Unknown"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setController.updatePrinter(device.name ?? 'Unknown');
                      Get.back();
                    },
                  ),
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Tutup"),
          ),
          ElevatedButton.icon(
            onPressed: () => setController.scanPrinters(),
            icon: Icon(Icons.refresh, size: 20),
            label: Text("Scan Ulang"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
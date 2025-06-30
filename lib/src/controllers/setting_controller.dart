import 'dart:typed_data';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/src/enum_tool.dart' as bt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:sadean/src/routers/constant.dart';

import '../models/transaction_model.dart';
import '../service/thermal_print_service.dart';

class SettingsController extends GetxController {
  var isLoading = false.obs;
  var userName = "John Doe".obs;
  var userEmail = "john.doe@example.com".obs;
  var userPhone = "+62 812 3456 7890".obs;
  var profileImage = "".obs;

  // Secure Storage instance
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Settings
  var isDarkMode = false.obs;
  var isNotificationEnabled = true.obs;
  var selectedLanguage = "Indonesia".obs;
  var selectedCurrency = "IDR".obs;
  var selectedPaymentMethod = "Cash".obs;
  var selectedPrinter = "Tidak Ada".obs;
  var printers = <BluetoothDevice>[].obs;
  var selectedPrinterDevice = Rxn<BluetoothDevice>();
  final EscCommand _esc = EscCommand();

  // Language options
  final languages = ["Indonesia", "English", "Malaysia"].obs;

  // Currency options
  final currencies = ["IDR", "USD", "MYR"].obs;

  // Payment method options
  final paymentMethods = ["Cash", "Credit Card", "Debit Card", "E-Wallet", "Bank Transfer"].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadSettings();
    scanPrinters();
  }

  // Load settings from secure storage
  Future<void> loadSettings() async {
    try {
      final darkMode = await _storage.read(key: 'dark_mode');
      if (darkMode != null) {
        isDarkMode.value = darkMode == 'true';
      }

      final notification = await _storage.read(key: 'notification_enabled');
      if (notification != null) {
        isNotificationEnabled.value = notification == 'true';
      }

      final language = await _storage.read(key: 'selected_language');
      if (language != null) {
        selectedLanguage.value = language;
      }

      final currency = await _storage.read(key: 'selected_currency');
      if (currency != null) {
        selectedCurrency.value = currency;
      }

      final paymentMethod = await _storage.read(key: 'selected_payment_method');
      if (paymentMethod != null) {
        selectedPaymentMethod.value = paymentMethod;
      }

      final printer = await _storage.read(key: 'selected_printer');
      if (printer != null) {
        selectedPrinter.value = printer;
      }

      final printerAddress = await _storage.read(key: 'selected_printer_address');
      if (printerAddress != null) {
        // Try to find the saved printer in available devices
        await scanPrinters();
        selectedPrinterDevice.value = printers.firstWhereOrNull(
              (device) => device.address == printerAddress,
        );
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Save settings to secure storage
  Future<void> saveSettings() async {
    try {
      await _storage.write(key: 'dark_mode', value: isDarkMode.value.toString());
      await _storage.write(key: 'notification_enabled', value: isNotificationEnabled.value.toString());
      await _storage.write(key: 'selected_language', value: selectedLanguage.value);
      await _storage.write(key: 'selected_currency', value: selectedCurrency.value);
      await _storage.write(key: 'selected_payment_method', value: selectedPaymentMethod.value);
      await _storage.write(key: 'selected_printer', value: selectedPrinter.value);

      if (selectedPrinterDevice.value != null) {
        await _storage.write(key: 'selected_printer_address', value: selectedPrinterDevice.value!.address ?? '');
      }
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  void loadUserData() {
    isLoading.value = true;
    // Simulate API call
    Future.delayed(Duration(seconds: 1), () {
      isLoading.value = false;
    });
  }

  void updateProfile({String? name, String? email, String? phone}) {
    if (name != null) userName.value = name;
    if (email != null) userEmail.value = email;
    if (phone != null) userPhone.value = phone;

    Get.snackbar(
      "Berhasil",
      "Profil berhasil diperbarui",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    saveSettings();
  }

  void toggleNotification() {
    isNotificationEnabled.value = !isNotificationEnabled.value;
    saveSettings();
    Get.snackbar(
      "Notifikasi",
      isNotificationEnabled.value ? "Notifikasi diaktifkan" : "Notifikasi dinonaktifkan",
      snackPosition: SnackPosition.TOP,
    );
  }

  void updateLanguage(String language) {
    selectedLanguage.value = language;
    saveSettings();
    Get.snackbar(
      "Bahasa",
      "Bahasa diubah ke $language",
      snackPosition: SnackPosition.TOP,
    );
  }

  void updateCurrency(String currency) {
    selectedCurrency.value = currency;
    saveSettings();
    Get.snackbar(
      "Mata Uang",
      "Mata uang diubah ke $currency",
      snackPosition: SnackPosition.TOP,
    );
  }

  void updatePaymentMethod(String method) {
    selectedPaymentMethod.value = method;
    saveSettings();
    Get.snackbar(
      "Metode Pembayaran",
      "Metode pembayaran diubah ke $method",
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> scanPrinters() async {
    printers.clear();
    await BluetoothPrintPlus.startScan(timeout: Duration(seconds: 4));
    BluetoothPrintPlus.scanResults.listen((results) {
      printers.assignAll(results);
    });
  }

  void updatePrinter(String printerName) {
    selectedPrinter.value = printerName;
    selectedPrinterDevice.value =
        printers.firstWhereOrNull((d) => d.name == printerName);
    connectSelectedPrinter();
    saveSettings();
  }

  Future<bool> connectSelectedPrinter() async {
    if (selectedPrinterDevice.value == null) return false;
    return await BluetoothPrintPlus.connect(selectedPrinterDevice.value!);
  }

  Future<void> disconnectPrinter() async {
    await BluetoothPrintPlus.disconnect();
  }

  // Helper function to format currency
  String formatCurrency(double amount) {
    if (selectedCurrency.value == 'IDR') {
      return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    } else if (selectedCurrency.value == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    } else if (selectedCurrency.value == 'MYR') {
      return 'RM${amount.toStringAsFixed(2)}';
    }
    return amount.toStringAsFixed(2);
  }

  // Helper function to create a properly spaced line
  String createSpacedLine(String left, String right, int width) {
    int space = width - left.length - right.length;
    if (space < 1) space = 1;
    return '$left${' ' * space}$right';
  }

  // Helper function to center text
  String centerText(String text, int width) {
    if (text.length >= width) return text;
    int spaces = (width - text.length) ~/ 2;
    return (' ' * spaces) + text + (' ' * spaces);
  }

  Future<void> printTransaction({
    required String customerName,
    required String customerLocation,
    required String customerPhone,
    required String dateTime,
    required List<TransactionItem> items,
    required String subtotal,
    required String adminFee,
    required String total,
    required String payment,
    required String change,
    required String status,
    required String trxCode,
  }) async {
    try {
      // if (selectedPrinterDevice.value == null) {
      //   Get.snackbar(
      //     "Error",
      //     "Printer belum dipilih",
      //     snackPosition: SnackPosition.TOP,
      //     backgroundColor: Colors.red,
      //     colorText: Colors.white,
      //   );
      //   return;
      // }
      //
      // // Try to connect to printer
      // final connected = await connectSelectedPrinter();
      // if (!connected) {
      //   Get.snackbar(
      //     "Error",
      //     "Gagal terhubung ke printer",
      //     snackPosition: SnackPosition.TOP,
      //     backgroundColor: Colors.red,
      //     colorText: Colors.white,
      //   );
      //   return;
      // }

      await _esc.cleanCommand();

      const int lineWidth = 32;
      const String separator = '---------------------------------';

      // Header - Store Info
      await _esc.text(
        content: centerText(customerName, lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: centerText(customerLocation, lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(
        content: centerText(customerPhone, lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: separator);

      // Transaction Info
      await _esc.text(
        content: centerText('NOTA TRANSAKSI', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');
      await _esc.text(content: createSpacedLine('Tanggal', dateTime.split(' ')[0], lineWidth));
      await _esc.text(content: createSpacedLine('Waktu', dateTime.split(' ')[1], lineWidth));
      await _esc.text(
        content: centerText('No. Transaksi', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: centerText(trxCode, lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: separator);
      await _esc.text(content: '');
      // Items Header
      await _esc.text(
        content: 'ITEM PEMBELIAN',
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');

      // Items
      for (var item in items) {
        final name = item.productName;
        final qty = item.quantity;
        final price = item.costPrice;
        final totalPrice = item.totalPrice;

        // Nama produk dipotong bila terlalu panjang
        String displayName = name.length > lineWidth ? name.substring(0, lineWidth - 3) + '...' : name;
        await _esc.text(content: displayName);

        // Format: 2x5.000         10.000
        String qtyPrice = '${qty}x${formatCurrency(price)}';
        String totalStr = formatCurrency(totalPrice);
        await _esc.text(content: createSpacedLine(qtyPrice, totalStr, lineWidth));
        await _esc.text(content: '');
      }

      await _esc.text(content: separator);

      // Summary
      double subtotalAmount = double.tryParse(subtotal.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      double adminFeeAmount = double.tryParse(adminFee.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      double totalAmount = double.tryParse(total.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      double paymentAmount = double.tryParse(payment.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      double changeAmount = double.tryParse(change.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

      await _esc.text(content: createSpacedLine('Subtotal', formatCurrency(subtotalAmount), lineWidth));
      await _esc.text(content: createSpacedLine('Biaya Admin', formatCurrency(adminFeeAmount), lineWidth));
      await _esc.text(content: '');

      await _esc.text(
        content: createSpacedLine('TOTAL', formatCurrency(totalAmount), lineWidth),
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );

      await _esc.text(content: separator);

      await _esc.text(content: createSpacedLine('Pembayaran', formatCurrency(paymentAmount), lineWidth));
      await _esc.text(content: createSpacedLine('Kembali', formatCurrency(changeAmount), lineWidth));
      await _esc.text(content: '');

      // Payment Method
      await _esc.text(
        content: centerText(selectedPaymentMethod.value.toUpperCase(), lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');

      // Status
      await _esc.text(
        content: centerText(status.toUpperCase(), lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );

      await _esc.text(content: '');
      await _esc.text(content: separator);

      // Footer
      await _esc.text(
        content: centerText('TERIMA KASIH', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(
        content: centerText('ATAS KUNJUNGAN ANDA', lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      // Print the receipt
      await _esc.print();

      final cmd = await _esc.getCommand();
      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
        Get.snackbar(
          "Berhasil",
          "Struk berhasil dicetak",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      print("Print error: $e");
      // Try to reconnect and retry
      try {
        await BluetoothPrintPlus.connect(selectedPrinterDevice.value!);
        await Future.delayed(Duration(milliseconds: 1000));

        final cmd = await _esc.getCommand();
        if (cmd != null) {
          await BluetoothPrintPlus.write(cmd);
          Get.snackbar(
            "Berhasil",
            "Struk berhasil dicetak setelah reconnect",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } catch (retryError) {
        Get.snackbar(
          "Error",
          "Gagal mencetak struk: $retryError",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void showFAQ() {
    Get.toNamed(faqRoute);
  }

  void showPrivacyPolicy() {
    Get.toNamed(privasiRoute);
  }

  void contactUs() {
    Get.toNamed(contactRoute);
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: Text("Konfirmasi Logout"),
        content: Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // Clear secure storage on logout
              await _storage.deleteAll();
              // Clear user data and navigate to login
              Get.offAllNamed(loginRoute);
              Get.snackbar(
                "Logout",
                "Berhasil keluar dari aplikasi",
                snackPosition: SnackPosition.TOP,
              );
            },
            child: Text("Logout"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    // Disconnect printer when controller is disposed
    disconnectPrinter();
    super.onClose();
  }
}
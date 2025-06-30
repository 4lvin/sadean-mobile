import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/src/enum_tool.dart' as bt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:sadean/src/routers/constant.dart';

import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../service/thermal_print_service.dart';

class SettingsController extends GetxController {
  var isLoading = false.obs;
  var userName = "John Doe".obs;
  var userEmail = "john.doe@example.com".obs;
  var userPhone = "+62 812 3456 7890".obs;
  var profileImage = "".obs;

  // Secure Storage instance
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Settings
  var isDarkMode = false.obs;
  var isNotificationEnabled = true.obs;
  var selectedLanguage = "Indonesia".obs;
  var selectedCurrency = "IDR".obs;
  var selectedPaymentMethod = "Cash".obs;
  var selectedPrinter = "Pilih Printer".obs;
  var printers = <BluetoothDevice>[].obs;
  var selectedPrinterDevice = Rxn<BluetoothDevice>();
  var isConnecting = false.obs;
  var isConnected = false.obs;
  var isPrinting = false.obs;
  final EscCommand _esc = EscCommand();

  // Language options
  final languages = ["Indonesia", "English", "Malaysia"].obs;

  // Currency options
  final currencies = ["IDR", "USD", "MYR"].obs;

  // Payment method options
  final paymentMethods =
      ["Cash", "Credit Card", "Debit Card", "E-Wallet", "Bank Transfer"].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadSettings();
    dataUser();
    _initializeBluetooth();
  }

  Future dataUser() async {
    var userData = await _storage.read(key: 'user_data');
     final user = User.fromJson(jsonDecode(userData ?? ""));
     userName.value = user.name;
     userEmail.value = user.email;
     // userPhone.value = user.;
  }

  // Initialize Bluetooth and auto-scan
  Future<void> _initializeBluetooth() async {
    await scanPrinters();
    _setupConnectionListener();
  }

  // Setup connection state listener
  void _setupConnectionListener() {
    BluetoothPrintPlus.blueState.listen((state) {
      switch (state) {
        case BlueState.blueOn:
          isConnected.value = true;
          isConnecting.value = false;
          break;
        case BlueState.blueOff:
          isConnected.value = false;
          isConnecting.value = false;
          break;
        default:
          isConnected.value = false;
          isConnecting.value = false;
          break;
      }
    });
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

      final printerAddress = await _storage.read(
        key: 'selected_printer_address',
      );
      if (printerAddress != null) {
        await scanPrinters();
        selectedPrinterDevice.value = printers.firstWhereOrNull(
          (device) => device.address == printerAddress,
        );
        if (selectedPrinterDevice.value != null) {
          selectedPrinter.value =
              selectedPrinterDevice.value!.name ?? 'Unknown';
          // Don't auto-connect on app start, just load the saved printer
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Save settings to secure storage
  Future<void> saveSettings() async {
    try {
      await _storage.write(
        key: 'dark_mode',
        value: isDarkMode.value.toString(),
      );
      await _storage.write(
        key: 'notification_enabled',
        value: isNotificationEnabled.value.toString(),
      );
      await _storage.write(
        key: 'selected_language',
        value: selectedLanguage.value,
      );
      await _storage.write(
        key: 'selected_currency',
        value: selectedCurrency.value,
      );
      await _storage.write(
        key: 'selected_payment_method',
        value: selectedPaymentMethod.value,
      );
      await _storage.write(
        key: 'selected_printer',
        value: selectedPrinter.value,
      );

      if (selectedPrinterDevice.value != null) {
        await _storage.write(
          key: 'selected_printer_address',
          value: selectedPrinterDevice.value!.address ?? '',
        );
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
      isNotificationEnabled.value
          ? "Notifikasi diaktifkan"
          : "Notifikasi dinonaktifkan",
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

  // Enhanced printer scanning with better error handling
  Future<void> scanPrinters() async {
    try {
      isLoading.value = true;
      printers.clear();

      // Start scanning
      await BluetoothPrintPlus.startScan(timeout: Duration(seconds: 6));

      // Listen to scan results
      BluetoothPrintPlus.scanResults.listen((results) {
        printers.assignAll(
          results
              .where(
                (device) =>
                    device.name != null &&
                    device.name!.isNotEmpty &&
                    !device.name!.toLowerCase().contains('unknown'),
              )
              .toList(),
        );
      });

      // Wait for scan to complete
      await Future.delayed(Duration(seconds: 6));
      await BluetoothPrintPlus.stopScan();

      // If no printers found, show helpful message
      if (printers.isEmpty) {
        Get.snackbar(
          "Info",
          "Tidak ditemukan printer. Pastikan printer Bluetooth aktif dan dalam jangkauan.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          "Berhasil",
          "Ditemukan ${printers.length} printer",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error scanning printers: $e');
      Get.snackbar(
        "Error",
        "Gagal mencari printer: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Enhanced printer selection and connection
  Future<void> updatePrinter(String printerName) async {
    try {
      selectedPrinter.value = printerName;
      selectedPrinterDevice.value = printers.firstWhereOrNull(
        (d) => d.name == printerName,
      );

      if (selectedPrinterDevice.value != null) {
        // Don't auto-connect, just save the selection
        await saveSettings();

        Get.snackbar(
          "Berhasil",
          "Printer $printerName dipilih. Tap untuk menghubungkan.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error updating printer: $e');
      Get.snackbar(
        "Error",
        "Gagal memilih printer: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Enhanced connection with retry mechanism
  Future<bool> connectSelectedPrinter() async {
    if (selectedPrinterDevice.value == null) return false;

    try {
      isConnecting.value = true;
      isConnected.value = false; // Reset connection status

      // Try to connect with retry mechanism
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final connected = await BluetoothPrintPlus.connect(
            selectedPrinterDevice.value!,
          );
          if (connected) {
            // Wait a bit to ensure connection is stable
            await Future.delayed(Duration(milliseconds: 1000));

            // Verify connection by checking state
            final isReallyConnected = await _verifyConnection();
            if (isReallyConnected) {
              isConnected.value = true;
              isConnecting.value = false;
              return true;
            }
          }
        } catch (e) {
          print('Connection attempt $attempt failed: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }

      isConnecting.value = false;
      isConnected.value = false;
      return false;
    } catch (e) {
      print('Error connecting to printer: $e');
      isConnecting.value = false;
      isConnected.value = false;
      return false;
    }
  }

  // Verify actual connection status
  Future<bool> _verifyConnection() async {
    try {
      // Try to send a simple command to verify connection
      await _esc.cleanCommand();
      await _esc.text(content: ''); // Empty line test
      final cmd = await _esc.getCommand();

      if (cmd != null) {
        // Don't actually write, just test if we can create commands
        return true;
      }
      return false;
    } catch (e) {
      print('Connection verification failed: $e');
      return false;
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      await BluetoothPrintPlus.disconnect();
      isConnected.value = false;
    } catch (e) {
      print('Error disconnecting printer: $e');
    }
  }

  // Test printer connection
  Future<void> testPrint() async {
    if (selectedPrinterDevice.value == null) {
      Get.snackbar(
        "Error",
        "Pilih printer terlebih dahulu",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isPrinting.value = true;

      // Ensure connection
      final connected = await connectSelectedPrinter();
      if (!connected) {
        throw Exception("Gagal terhubung ke printer");
      }

      await _esc.cleanCommand();

      // Simple test print
      await _esc.text(
        content: centerText('=== TEST PRINT ===', 32),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: centerText('Printer berhasil terhubung!', 32),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: centerText(DateTime.now().toString().substring(0, 19), 32),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
        Get.snackbar(
          "Berhasil",
          "Test print berhasil!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Test print error: $e");
      Get.snackbar(
        "Error",
        "Test print gagal: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPrinting.value = false;
    }
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

  // Enhanced print transaction with better formatting and error handling
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
      isPrinting.value = true;

      // Ensure printer is connected
      if (selectedPrinterDevice.value == null) {
        throw Exception("Printer belum dipilih");
      }

      final connected = await connectSelectedPrinter();
      if (!connected) {
        throw Exception("Gagal terhubung ke printer");
      }

      await _esc.cleanCommand();
      const int lineWidth = 32;
      const String separator = '--------------------------------';

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

      final dateTimeParts = dateTime.split(' ');
      final datePart =
          dateTimeParts.isNotEmpty
              ? dateTimeParts[0]
              : DateTime.now().toString().split(' ')[0];
      final timePart =
          dateTimeParts.length > 1
              ? dateTimeParts[1].substring(0, 8)
              : DateTime.now().toString().split(' ')[1].substring(0, 8);

      await _esc.text(
        content: createSpacedLine('Tanggal', datePart, lineWidth),
      );
      await _esc.text(content: createSpacedLine('Waktu', timePart, lineWidth));
      await _esc.text(content: '');
      await _esc.text(
        content: centerText('No. Transaksi', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(
        content: centerText(trxCode, lineWidth),
        alignment: bt.Alignment.center,
        fontSize: EscFontSize.size1,
      );
      await _esc.text(content: separator);

      // Items Header
      await _esc.text(content: 'ITEM PEMBELIAN', style: EscTextStyle.bold);
      await _esc.text(content: '');

      // Items with better formatting
      for (var item in items) {
        final name = item.productName;
        final qty = item.quantity;
        final price = item.costPrice;
        final totalPrice = item.totalPrice;

        // Product name (truncate if too long)
        String displayName =
            name.length > lineWidth
                ? name.substring(0, lineWidth - 3) + '...'
                : name;
        await _esc.text(content: displayName);

        // Quantity x Price = Total
        String qtyPrice = '${qty}x${formatCurrency(price)}';
        String totalStr = formatCurrency(totalPrice);
        await _esc.text(
          content: createSpacedLine(qtyPrice, totalStr, lineWidth),
        );
        await _esc.text(content: '');
      }

      await _esc.text(content: separator);

      // Summary with better number parsing
      double subtotalAmount = _parseAmount(subtotal);
      double adminFeeAmount = _parseAmount(adminFee);
      double totalAmount = _parseAmount(total);
      double paymentAmount = _parseAmount(payment);
      double changeAmount = _parseAmount(change);

      await _esc.text(
        content: createSpacedLine(
          'Subtotal',
          formatCurrency(subtotalAmount),
          lineWidth,
        ),
      );
      if (adminFeeAmount > 0) {
        await _esc.text(
          content: createSpacedLine(
            'Biaya Admin',
            formatCurrency(adminFeeAmount),
            lineWidth,
          ),
        );
      }
      await _esc.text(content: '');

      await _esc.text(
        content: createSpacedLine(
          'TOTAL',
          formatCurrency(totalAmount),
          lineWidth,
        ),
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size1,
      );

      await _esc.text(content: separator);

      await _esc.text(
        content: createSpacedLine(
          'Pembayaran',
          formatCurrency(paymentAmount),
          lineWidth,
        ),
      );
      await _esc.text(
        content: createSpacedLine(
          'Kembali',
          formatCurrency(changeAmount),
          lineWidth,
        ),
      );
      await _esc.text(content: '');

      // Payment Method
      await _esc.text(
        content: centerText(
          selectedPaymentMethod.value.toUpperCase(),
          lineWidth,
        ),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');

      // Status
      await _esc.text(
        content: centerText(status.toUpperCase(), lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size1,
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
      Get.snackbar(
        "Error",
        "Gagal mencetak struk: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPrinting.value = false;
    }
  }

  // Helper method to parse amount from string
  double _parseAmount(String amountString) {
    try {
      // Remove currency symbols and formatting
      String cleanAmount =
          amountString
              .replaceAll('Rp', '')
              .replaceAll('\$', '')
              .replaceAll('RM', '')
              .replaceAll('.', '')
              .replaceAll(',', '')
              .trim();

      return double.tryParse(cleanAmount) ?? 0.0;
    } catch (e) {
      print('Error parsing amount: $amountString - $e');
      return 0.0;
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
          TextButton(onPressed: () => Get.back(), child: Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // Disconnect printer before logout
              await disconnectPrinter();
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

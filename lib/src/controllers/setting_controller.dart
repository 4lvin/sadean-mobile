import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:sadean/src/routers/constant.dart';

import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../service/api_service.dart';
import '../service/database_helper.dart';
import 'improve_print_controller.dart';

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
  final ApiProvider _apiProvider = Get.put(ApiProvider()); // Get ApiProvider instance
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  // Settings
  var isDarkMode = false.obs;
  var isNotificationEnabled = true.obs;
  var selectedLanguage = "Indonesia".obs;
  var selectedCurrency = "IDR".obs;
  var selectedPaymentMethod = "Cash".obs;

  // Receipt Settings
  var storeName = "SADEAN".obs;
  var storeAddress = "Pandaan, Pasuruan".obs;
  var storePhone = "085736710089".obs;
  var receiptFooterNote = "Terima kasih atas kunjungan Anda".obs;

  // Bluetooth print service
  late ImprovedBluetoothPrintService printService;

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
    // Initialize bluetooth print service
    printService = Get.put(ImprovedBluetoothPrintService());

    loadUserData();
    loadSettings();
    dataUser();
  }

  Future dataUser() async {
    var userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      final user = User.fromJson(jsonDecode(userData));
      userName.value = user.name;
      userEmail.value = user.email;
    }
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

      final storeNameData = await _storage.read(key: 'store_name');
      if (storeNameData != null) {
        storeName.value = storeNameData;
      }

      final storeAddressData = await _storage.read(key: 'store_address');
      if (storeAddressData != null) {
        storeAddress.value = storeAddressData;
      }

      final storePhoneData = await _storage.read(key: 'store_phone');
      if (storePhoneData != null) {
        storePhone.value = storePhoneData;
      }

      final footerNote = await _storage.read(key: 'receipt_footer_note');
      if (footerNote != null) {
        receiptFooterNote.value = footerNote;
      }

      // Load saved printer
      await _loadSavedPrinter();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Load saved printer from storage
  Future<void> _loadSavedPrinter() async {
    try {
      final printerName = await _storage.read(key: 'selected_printer_name');
      final printerAddress = await _storage.read(key: 'selected_printer_address');

      if (printerName != null && printerAddress != null) {
        // Scan to find the saved printer
        await printService.startScan(timeout: Duration(seconds: 5));

        // Wait for scan results
        await Future.delayed(Duration(seconds: 5));

        // Find the saved printer
        final savedPrinter = printService.devices.firstWhereOrNull(
                (device) => device.address == printerAddress && device.name == printerName
        );

        if (savedPrinter != null) {
          printService.selectDevice(savedPrinter);
          print('Saved printer found and selected: ${savedPrinter.name}');
        }
      }
    } catch (e) {
      print('Error loading saved printer: $e');
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

      // Save receipt settings
      await _storage.write(
        key: 'store_name',
        value: storeName.value,
      );
      await _storage.write(
        key: 'store_address',
        value: storeAddress.value,
      );
      await _storage.write(
        key: 'store_phone',
        value: storePhone.value,
      );
      await _storage.write(
        key: 'receipt_footer_note',
        value: receiptFooterNote.value,
      );

      // Save selected printer
      if (printService.selectedDevice.value != null) {
        await _storage.write(
          key: 'selected_printer_name',
          value: printService.selectedDevice.value!.name ?? '',
        );
        await _storage.write(
          key: 'selected_printer_address',
          value: printService.selectedDevice.value!.address ?? '',
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

  // Printer related methods
  Future<void> scanPrinters() async {
    await printService.startScan();
  }

  Future<void> selectPrinter(int index) async {
    if (index < printService.devices.length) {
      printService.selectDevice(printService.devices[index]);
      await saveSettings();
    }
  }

  Future<bool> connectPrinter() async {
    if (printService.selectedDevice.value == null) {
      Get.snackbar(
        "Error",
        "Pilih printer terlebih dahulu",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return await printService.connect();
  }

  Future<void> disconnectPrinter() async {
    await printService.disconnect();
  }

  Future<bool> testPrint() async {
    return await printService.testPrint();
  }

  // Print transaction with improved service
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
    required String footerNote,
  }) async {
    try {
      // Parse amounts
      double subtotalAmount = _parseAmount(subtotal);
      double adminFeeAmount = _parseAmount(adminFee);
      double totalAmount = _parseAmount(total);
      double paymentAmount = _parseAmount(payment);
      double changeAmount = _parseAmount(change);

      // Parse date time
      DateTime transactionDate = DateTime.tryParse(dateTime) ?? DateTime.now();

      await printService.printReceipt(
        storeName: customerName,
        storeAddress: customerLocation,
        storePhone: customerPhone,
        items: items,
        subtotal: subtotalAmount,
        adminFee: adminFeeAmount,
        total: totalAmount,
        payment: paymentAmount,
        change: changeAmount,
        paymentMethod: selectedPaymentMethod.value,
        transactionId: trxCode,
        dateTime: transactionDate,
        footerNote: footerNote
      );
    } catch (e) {
      print("Print transaction error: $e");
      Get.snackbar(
        "Error",
        "Gagal mencetak struk: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to parse amount from string
  double _parseAmount(String amountString) {
    try {
      String cleanAmount = amountString
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

  // Helper function to format currency
  String formatCurrency(double amount) {
    if (selectedCurrency.value == 'IDR') {
      return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    } else if (selectedCurrency.value == 'USD') {
      return '\${amount.toStringAsFixed(2)}';
    } else if (selectedCurrency.value == 'MYR') {
      return 'RM${amount.toStringAsFixed(2)}';
    }
    return amount.toStringAsFixed(2);
  }

  // Show receipt settings dialog
  void showReceiptSettingsDialog() {
    final storeNameController = TextEditingController(text: storeName.value);
    final storeAddressController = TextEditingController(text: storeAddress.value);
    final storePhoneController = TextEditingController(text: storePhone.value);
    final footerNoteController = TextEditingController(text: receiptFooterNote.value);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.blue),
            SizedBox(width: 12),
            Text('Pengaturan Struk'),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: Get.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: storeNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Toko',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: storeAddressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat Toko',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: storePhoneController,
                  decoration: InputDecoration(
                    labelText: 'No. Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: footerNoteController,
                  decoration: InputDecoration(
                    labelText: 'Catatan Footer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Contoh: Terima kasih atas kunjungan Anda',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              storeName.value = storeNameController.text;
              storeAddress.value = storeAddressController.text;
              storePhone.value = storePhoneController.text;
              receiptFooterNote.value = footerNoteController.text;

              saveSettings();
              Get.back();
              Get.snackbar(
                'Berhasil',
                'Pengaturan struk berhasil disimpan',
                backgroundColor: Colors.green.shade100,
                colorText: Colors.green.shade800,
              );
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
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

  // Updated method for uploading database data as a .db file
  Future<void> uploadDatabaseData() async {
    isLoading.value = true;
    try {
      Get.snackbar(
        "Info",
        "Mempersiapkan file database untuk diunggah...",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        showProgressIndicator: true,
      );

      // Get the path to the SQLite database file
      final dbPath = await _dbHelper.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        Get.snackbar(
          "Peringatan",
          "File database tidak ditemukan.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      Get.snackbar(
        "Info",
        "Mengunggah file database ke server...",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        showProgressIndicator: true,
      );

      // Call the API method to upload the SQLite .db file
      final response = await _apiProvider.uploadSqliteBackup(dbFile);

      if (response['status'] == true || response['success'] == true) {
        Get.snackbar(
          "Berhasil",
          response['message'] ?? "File backup database berhasil diunggah!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          "Gagal Unggah",
          response['message'] ?? "Terjadi kesalahan saat mengunggah file backup.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('Error uploading database file: $e');
      Get.snackbar(
        "Error",
        "Gagal mengunggah file database: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      if (Get.isSnackbarOpen) {
        Get.back(); // Dismiss progress indicator snackbar
      }
    }
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
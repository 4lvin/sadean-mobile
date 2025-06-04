import 'dart:typed_data';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/src/enum_tool.dart' as bt;
import 'package:flutter/material.dart';
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


  // Settings
  var isDarkMode = false.obs;
  var isNotificationEnabled = true.obs;
  var selectedLanguage = "Indonesia".obs;
  var selectedCurrency = "IDR".obs;
  var selectedPaymentMethod = "Cash".obs;
  var selectedPrinter = "Tidak Ada".obs;
  var printers = <BluetoothDevice>[].obs;  // daftar perangkat Bluetooth ditemukan
  var selectedPrinterDevice = Rxn<BluetoothDevice>(); // device yang dipilih
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
    scanPrinters();
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
  }

  void toggleNotification() {
    isNotificationEnabled.value = !isNotificationEnabled.value;
    Get.snackbar(
      "Notifikasi",
      isNotificationEnabled.value ? "Notifikasi diaktifkan" : "Notifikasi dinonaktifkan",
      snackPosition: SnackPosition.TOP,
    );
  }

  void updateLanguage(String language) {
    selectedLanguage.value = language;
    // Implement language change logic here
    Get.snackbar(
      "Bahasa",
      "Bahasa diubah ke $language",
      snackPosition: SnackPosition.TOP,
    );
  }

  void updateCurrency(String currency) {
    selectedCurrency.value = currency;
    Get.snackbar(
      "Mata Uang",
      "Mata uang diubah ke $currency",
      snackPosition: SnackPosition.TOP,
    );
  }

  void updatePaymentMethod(String method) {
    selectedPaymentMethod.value = method;
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
    // Bisa juga simpan ke storage jika mau persistent
  }

  Future<bool> connectSelectedPrinter() async {
    if (selectedPrinterDevice.value == null) return false;
    return await BluetoothPrintPlus.connect(selectedPrinterDevice.value!);
  }

  Future<void> disconnectPrinter() async {
    await BluetoothPrintPlus.disconnect();
  }

  Future<void> printTransaction({
    required String customerName,
    required String customerLocation,
    required String customerPhone,
    required String dateTime,
    required List<TransactionItem> items, // {'name': ..., 'qty': ..., 'price': ..., 'total': ...}
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
      //   throw Exception('No Bluetooth device selected');
      // }
      //
      // final connected = await BluetoothPrintService().connect();
      // await Future.delayed(Duration(milliseconds: 500));
      // if (!connected) {
      //   throw Exception('Failed to connect to Bluetooth device');
      // }
      await _esc.cleanCommand();

      // Header
      const int lineWidth = 32;

      await _esc.text(content: customerName, alignment: bt.Alignment.center, style: EscTextStyle.bold, fontSize: EscFontSize.size2);
      await _esc.text(content: "");
      await _esc.text(content: customerLocation, alignment: bt.Alignment.center);
      await _esc.text(content: "");
      await _esc.text(content: customerPhone, alignment: bt.Alignment.center);
      await _esc.text(content: "");
      await _esc.text(content: 'Tanggal: $dateTime', alignment: bt.Alignment.center);
      await _esc.text(content: "");
      await _esc.text(content: '-' * lineWidth);

// Items
      for (var item in items) {
        final name = item.productName;
        final qty = item.quantity;
        final price = item.costPrice;
        final total = item.totalPrice;

        // Batasi nama produk jika terlalu panjang
        final truncatedName = name.length > lineWidth ? name.substring(0, lineWidth) : name;

        await _esc.text(content: truncatedName);
        await _esc.text(content: "");
        // Format kuantitas dan total
        final left = '$qty x $price';
        final right = total.toString();
        final spaces = lineWidth - left.length - right.length;
        await _esc.text(content: '$left${' ' * spaces}$right');
      }

      await _esc.text(content: '-' * lineWidth);

// Ringkasan
      String padLine(String label, String value, {bool bold = false}) {
        final pad = lineWidth - label.length - value.length;
        final text = '$label${' ' * pad}$value';
        return text;
      }

      await _esc.text(content: padLine('Subtotal', subtotal));
      await _esc.text(content: "");
      await _esc.text(content: padLine('Biaya Admin', adminFee));
      await _esc.text(content: "");
      await _esc.text(content: padLine('Total Akhir', total), style: EscTextStyle.bold);
      await _esc.text(content: "");
      await _esc.text(content: '-' * lineWidth);

// Pembayaran
      await _esc.text(content: padLine('Pembayaran', payment));
      await _esc.text(content: "");
      await _esc.text(content: padLine('Kembali', change));

      await _esc.text(content: '', alignment: bt.Alignment.center); // Baris kosong

// Status
      await _esc.text(
        content: status,
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );

      await _esc.text(content: '', alignment: bt.Alignment.center); // Baris kosong
      await _esc.text(content: 'Tunai', alignment: bt.Alignment.center);
      await _esc.text(content: trxCode, alignment: bt.Alignment.center);
      await _esc.text(content: dateTime, alignment: bt.Alignment.center);

// Extra blank lines untuk spasi bawah
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.print();


      final cmd = await _esc.getCommand();
      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
      }

    }catch (e) {
      print("Reconnect and retry printing...");
      await BluetoothPrintPlus.connect(selectedPrinterDevice.value!);
      await Future.delayed(Duration(milliseconds: 500));
      // await BluetoothPrintPlus.write(cmd);
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
            onPressed: () {
              Get.back();
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
}

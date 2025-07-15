import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/src/enum_tool.dart' as bt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class ImprovedBluetoothPrintService extends GetxController {
  final EscCommand _esc = EscCommand();
  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  // Observable variables
  var devices = <BluetoothDevice>[].obs;
  var selectedDevice = Rxn<BluetoothDevice>();
  var isScanning = false.obs;
  var isConnected = false.obs;
  var isConnecting = false.obs;
  var isPrinting = false.obs;

  // Stream subscriptions
  StreamSubscription? _scanSubscription, _stateSubscription, _connectSubscription;
  static const _printerNameKey = 'last_printer_name';
  static const _printerAddressKey = 'last_printer_address';
  @override
  void onInit() {
    super.onInit();
    _initializeListeners();
    Future.delayed(const Duration(seconds: 2), _loadAndConnectSavedPrinter);
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    _connectSubscription?.cancel();
    disconnect();
    super.onClose();
  }

  /// Initialize all listeners according to documentation
  void _initializeListeners() {
    _scanSubscription = BluetoothPrintPlus.scanResults.listen((d) {
      devices.value = d.where((i) => i.name?.isNotEmpty ?? false).toList();
    });

    _stateSubscription = BluetoothPrintPlus.blueState.listen((s) {
      if (s == BlueState.blueOff) {
        isConnected.value = false;
        isConnecting.value = false;
        _showError('Bluetooth tidak aktif.');
      }
    });

    _connectSubscription = BluetoothPrintPlus.connectState.listen((s) {
      isConnecting.value = false;
      isConnected.value = (s == ConnectState.connected);
      if (isConnected.value) {
        _savePrinter(selectedDevice.value!);
        _showSuccess('Terhubung ke ${selectedDevice.value?.name}');
      } else {
        if (selectedDevice.value != null) {
          _showWarning('Koneksi ke ${selectedDevice.value?.name} terputus');
        }
      }
    });
  }


  /// Request necessary permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) =>
    status == PermissionStatus.granted);

    if (!allGranted) {
      _showError('Izin Bluetooth diperlukan untuk menghubungkan printer');
      return false;
    }

    return true;
  }

  /// Check if Bluetooth is available and enabled
  Future<bool> checkBluetoothAvailability() async {
    try {
      // The plugin will automatically check bluetooth state
      // We can also use platform channels if needed
      return true;
    } catch (e) {
      _showError('Bluetooth tidak tersedia: $e');
      return false;
    }
  }

  /// Start scanning for devices
  Future<void> startScan() async {
    if (isScanning.value) return;
    if (!await requestPermissions()) return;
    devices.clear();
    try {
      isScanning.value = true;
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 5));
    } finally {
      isScanning.value = false;
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await BluetoothPrintPlus.stopScan();
    } catch (e) {
      print('Stop scan error: $e');
    }
  }

  Future<void> forgetPrinter() async {
    await disconnect();
    await _storage.delete(key: _printerNameKey);
    await _storage.delete(key: _printerAddressKey);
    selectedDevice.value = null;
    _showInfo("Printer telah dilupakan.");
  }

  Future<void> _savePrinter(BluetoothDevice device) async {
    await _storage.write(key: _printerNameKey, value: device.name);
    await _storage.write(key: _printerAddressKey, value: device.address);
  }

  Future<void> _loadAndConnectSavedPrinter() async {
    final name = await _storage.read(key: _printerNameKey);
    final address = await _storage.read(key: _printerAddressKey);
    if (address != null && name != null) {
      final savedDevice = BluetoothDevice(name,address);
      connect(savedDevice);
    }
  }

  /// Select a device
  void selectDevice(BluetoothDevice device) {
    selectedDevice.value = device;
    _showInfo('Printer ${device.name} dipilih');
  }

  /// Connect to selected device
  Future<void> connect(BluetoothDevice device) async {
    if (isConnecting.value || (isConnected.value && selectedDevice.value?.address == device.address)) {
      return;
    }
    try {
      isConnecting.value = true;
      selectedDevice.value = device;
      await BluetoothPrintPlus.connect(device);
    } catch (e) {
      isConnecting.value = false;
      _showError('Gagal terhubung: ${e.toString()}');
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
    } catch (_) {}
    isConnected.value = false;
  }

  /// Test printer connection
  Future<bool> testPrint() async {
    if (!isConnected.value) {
      _showError('Printer tidak terhubung');
      return false;
    }

    try {
      isPrinting.value = true;

      await _esc.cleanCommand();

      // Simple test print according to documentation
      await _esc.text(
        content: _centerText('=== TEST PRINT ===', 32),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: _centerText('Printer berhasil terhubung!', 32),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: _centerText(DateTime.now().toString().substring(0, 19), 32),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      // Print according to documentation
      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd == null) {
        _showError('Gagal membuat perintah print');
        return false;
      }

      // Write to printer
      await BluetoothPrintPlus.write(cmd);

      _showSuccess('Test print berhasil!');
      return true;

    } catch (e) {
      print('Test print error: $e');
      _showError('Test print gagal: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  /// Print transaction receipt
  Future<void> printReceipt({
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required List<TransactionItem> items,
    required double subtotal,
    required double adminFee,
    required double total,
    required double payment,
    required double change,
    required String paymentMethod,
    required String transactionId,
    required DateTime dateTime,
    String? footerNote,
  }) async {
    if (!isConnected.value) return _showError('Printer tidak terhubung');
    if (isPrinting.value) return;

    try {
      isPrinting.value = true;

      final List<int> bytes = [];
      const int lineWidth = 32;
      final String separator = List.generate(lineWidth, (_) => '-').join();

      // Helper function to add commands to byte list
      void add(List<int> command) => bytes.addAll(command);
      void addText(String text) => bytes.addAll(text.codeUnits);
      void addLine(String text) {
        addText(text);
        add([0x0A]); // Line Feed
      }

      // Initialize printer
      add([0x1B, 0x40]); // ESC @

      // --- HEADER ---
      add([0x1B, 0x61, 0x01]); // Align Center
      add([0x1B, 0x21, 0x30]); // Font Size: Double Height & Width
      addLine(storeName.toUpperCase());
      add([0x1B, 0x21, 0x00]); // Font Size: Normal
      _splitText(storeAddress, lineWidth).forEach((line) => addLine(line));
      addLine(storePhone);
      // add([0x0A]);

      // --- INFO ---
      add([0x1B, 0x61, 0x00]); // Align Left
      addLine(separator);
      addLine(_leftRight('Tanggal', DateFormat('dd/MM/yy, HH:mm').format(dateTime), lineWidth));
      addLine(_leftRight('No. Ref', transactionId, lineWidth));
      // addLine(separator);
      add([0x0A]);


      // --- ITEMS ---
      for (final item in items) {
        // Line 1: Nama Produk
        _splitText(item.productName.toUpperCase(), lineWidth).forEach((line) => addLine(line));
        // Line 2: Qty x Harga & Total
        final qtyPrice = '${item.quantity} x ${_formatCurrency(item.unitPrice)}';
        final totalItem = _formatCurrency(item.quantity * item.unitPrice);
        addLine(_leftRight(qtyPrice, totalItem, lineWidth));
      }
      addLine(separator);

      // --- TOTALS ---
      addLine(_leftRight('Subtotal', _formatCurrency(subtotal), lineWidth));
      if (adminFee > 0) addLine(_leftRight('Admin', _formatCurrency(adminFee), lineWidth));

      add([0x1B, 0x21, 0x00]); // Font: Double Height, Bold
      addLine(_leftRight('TOTAL', _formatCurrency(total), lineWidth));
      add([0x1B, 0x21, 0x00]); // Font: Normal
      addLine(separator);

      // --- PAYMENT ---
      addLine(_leftRight('Bayar (${paymentMethod.toUpperCase()})', _formatCurrency(payment), lineWidth));
      addLine(_leftRight('Kembali', _formatCurrency(change), lineWidth));
      add([0x0A]);

      // --- FOOTER ---
      add([0x1B, 0x61, 0x01]); // Align Center
      add([0x1B, 0x21, 0x08]); // Font: Bold
      addLine('=== LUNAS ===');
      add([0x1B, 0x21, 0x00]); // Font: Normal
      addLine(separator);
      _splitText(footerNote ?? 'Terima Kasih Atas Kunjungan Anda', lineWidth)
          .forEach((line) => addLine(line));

      // Spacing at the end and cut paper
      add([0x0A, 0x0A, 0x0A, 0x0A]);
      add([0x1D, 0x56, 0x01]); // GS V 1 - Full cut

      await BluetoothPrintPlus.write(Uint8List.fromList(bytes));
      _showSuccess('Struk berhasil dicetak');

    } catch (e) {
      _showError('Gagal mencetak: ${e.toString()}');
    } finally {
      isPrinting.value = false;
    }
  }

  // --- HELPER METHODS FOR FORMATTING ---

  String _leftRight(String left, String right, int width) {
    final maxLeft = width - right.length - 1;
    if (left.length > maxLeft) {
      left = left.substring(0, maxLeft);
    }
    final spaces = ' ' * (width - left.length - right.length);
    return left + spaces + right;
  }

  String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) / 2;
    return (' ' * padding.floor()) + text + (' ' * padding.ceil());
  }

  List<String> _splitText(String text, int maxWidth) {
    final List<String> lines = [];
    final List<String> words = text.split(RegExp(r'\s+'));
    String currentLine = '';
    for (final word in words) {
      if ((currentLine.length + word.length + 1) <= maxWidth) {
        currentLine += '$word ';
      } else {
        lines.add(currentLine.trim());
        currentLine = '$word ';
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine.trim());
    return lines;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.decimalPattern('id_ID').format(amount);
  }
  // Notification helpers
  void _showSuccess(String message) {
    Get.snackbar(
      'Berhasil',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle, color: Colors.green),
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: Icon(Icons.error_outline, color: Colors.red),
      duration: Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showWarning(String message) {
    Get.snackbar(
      'Peringatan',
      message,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: Icon(Icons.warning_outlined, color: Colors.orange),
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: Icon(Icons.info_outline, color: Colors.blue),
      duration: Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }
}
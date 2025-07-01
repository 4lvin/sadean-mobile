import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/src/enum_tool.dart' as bt;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class ImprovedBluetoothPrintService extends GetxController {
  final EscCommand _esc = EscCommand();

  // Observable variables
  var devices = <BluetoothDevice>[].obs;
  var selectedDevice = Rxn<BluetoothDevice>();
  var isScanning = false.obs;
  var isConnected = false.obs;
  var isConnecting = false.obs;
  var isPrinting = false.obs;

  // Stream subscriptions
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BlueState>? _blueStateSubscription;
  StreamSubscription<ConnectState>? _connectStateSubscription;
  StreamSubscription<List<BluetoothDevice>>? _scanResultsSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeListeners();
  }

  /// Initialize all listeners according to documentation
  void _initializeListeners() {
    // Listen to scanning state
    _isScanningSubscription = BluetoothPrintPlus.isScanning.listen((scanning) {
      isScanning.value = scanning;
      print('********** isScanning: $scanning **********');
    });

    // Listen to bluetooth state changes
    _blueStateSubscription = BluetoothPrintPlus.blueState.listen((state) {
      print('********** blueState change: $state **********');
      switch (state) {
        case BlueState.blueOn:
        // Bluetooth is on, can proceed with operations
          break;
        case BlueState.blueOff:
          isConnected.value = false;
          isConnecting.value = false;
          _showError('Bluetooth dimatikan');
          break;
        default:
          break;
      }
    });

    // Listen to connection state
    _connectStateSubscription = BluetoothPrintPlus.connectState.listen((state) {
      print('********** connectState change: $state **********');
      switch (state) {
        case ConnectState.connected:
          isConnecting.value = false;
          isConnected.value = true;
          _showSuccess('Printer terhubung');
          break;
        case ConnectState.disconnected:
          isConnecting.value = false;
          isConnected.value = false;
          _showWarning('Printer terputus');
          break;
        default:
          break;
      }
    });

    // Listen to scan results
    _scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((results) {
      // Filter devices with valid names for thermal printers
      var filteredDevices = results.where((device) =>
      device.name != null &&
          device.name!.isNotEmpty &&
          !device.name!.toLowerCase().contains('unknown') &&
          (device.name!.toLowerCase().contains('printer') ||
              device.name!.toLowerCase().contains('pos') ||
              device.name!.toLowerCase().contains('thermal') ||
              device.name!.toLowerCase().contains('label') ||
              device.name!.toLowerCase().contains('receipt') ||
              // Common thermal printer brands
              device.name!.toLowerCase().contains('xprinter') ||
              device.name!.toLowerCase().contains('goojprt') ||
              device.name!.toLowerCase().contains('bluetooth printer'))
      ).toList();

      devices.assignAll(filteredDevices);
      print('Found ${devices.length} compatible printers');
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
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      // Check permissions first
      if (!await requestPermissions()) {
        return;
      }

      // Check bluetooth availability
      if (!await checkBluetoothAvailability()) {
        return;
      }

      // Clear previous results
      devices.clear();

      // Start scanning according to documentation
      await BluetoothPrintPlus.startScan(timeout: timeout);

      _showInfo('Mencari printer Bluetooth...');

      // Wait for scan to complete
      await Future.delayed(timeout);

      if (devices.isEmpty) {
        _showWarning('Tidak ditemukan printer. Pastikan printer aktif dan dalam mode pairing.');
      } else {
        _showSuccess('Ditemukan ${devices.length} printer');
      }

    } catch (e) {
      print('Scan error: $e');
      _showError('Gagal mencari printer: $e');
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

  /// Select a device
  void selectDevice(BluetoothDevice device) {
    selectedDevice.value = device;
    _showInfo('Printer ${device.name} dipilih');
  }

  /// Connect to selected device
  Future<bool> connect() async {
    if (selectedDevice.value == null) {
      _showError('Pilih printer terlebih dahulu');
      return false;
    }

    try {
      isConnecting.value = true;

      // Check if already connected
      if (isConnected.value) {
        await disconnect();
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Connect according to documentation
      await BluetoothPrintPlus.connect(selectedDevice.value!);

      // Wait for connection state to update
      await Future.delayed(Duration(seconds: 2));

      return isConnected.value;

    } catch (e) {
      print('Connection error: $e');
      isConnecting.value = false;
      _showError('Gagal terhubung: $e');
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      isConnected.value = false;
      isConnecting.value = false;
    } catch (e) {
      print('Disconnect error: $e');
    }
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
  Future<bool> printReceipt({
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
  }) async {
    if (!isConnected.value) {
      _showError('Printer tidak terhubung');
      return false;
    }

    try {
      isPrinting.value = true;

      await _esc.cleanCommand();

      // Optimal width for 58mm thermal paper
      const int lineWidth = 32;
      const String separator = '--------------------------------';
      const String thinSeparator = '................................';

      // Header - Store Info
      await _esc.text(
        content: _centerText(storeName, lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );

      // Store address - split if too long
      List<String> addressLines = _splitText(storeAddress, lineWidth);
      for (String line in addressLines) {
        await _esc.text(
          content: _centerText(line, lineWidth),
          alignment: bt.Alignment.center,
        );
      }

      await _esc.text(
        content: _centerText(storePhone, lineWidth),
        alignment: bt.Alignment.center,
      );

      await _esc.text(content: separator);

      // Transaction header
      await _esc.text(
        content: _centerText('NOTA TRANSAKSI', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: thinSeparator);

      // Date and time
      final dateStr = '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      await _esc.text(content: 'Tanggal: $dateStr');
      await _esc.text(content: 'Waktu  : $timeStr');
      await _esc.text(content: 'No.Ref : $transactionId');
      await _esc.text(content: separator);

      // Items header
      await _esc.text(content: 'ITEM PEMBELIAN');
      await _esc.text(content: thinSeparator);

      // Items list
      for (var item in items) {
        // Product name - allow wrapping for long names
        List<String> nameLines = _splitText(item.productName, lineWidth);
        for (String line in nameLines) {
          await _esc.text(content: line);
        }

        // Quantity, price, and total
        String qtyLine = '${item.quantity} x ${_formatCurrency(item.unitPrice)}';
        String totalLine = _formatCurrency(item.totalPrice);

        await _esc.text(content: _createRightAlignedLine(qtyLine, totalLine, lineWidth));
        await _esc.text(content: ''); // Space between items
      }

      await _esc.text(content: thinSeparator);

      // Summary section
      await _esc.text(content: _createSpacedLine('Subtotal', _formatCurrency(subtotal), lineWidth));

      if (adminFee > 0) {
        await _esc.text(content: _createSpacedLine('Admin', _formatCurrency(adminFee), lineWidth));
      }

      await _esc.text(content: separator);

      await _esc.text(
        content: _createSpacedLine('TOTAL', _formatCurrency(total), lineWidth),
        style: EscTextStyle.bold,
      );

      await _esc.text(content: separator);

      // Payment section
      await _esc.text(content: _createSpacedLine('Bayar', _formatCurrency(payment), lineWidth));
      await _esc.text(content: _createSpacedLine('Kembali', _formatCurrency(change), lineWidth));

      await _esc.text(content: '');
      await _esc.text(
        content: _centerText('Metode: $paymentMethod', lineWidth),
        alignment: bt.Alignment.center,
      );

      await _esc.text(content: '');
      await _esc.text(
        content: _centerText('=== LUNAS ===', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );

      await _esc.text(content: separator);

      // Footer
      await _esc.text(
        content: _centerText('TERIMA KASIH', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(
        content: _centerText('SELAMAT BERBELANJA', lineWidth),
        alignment: bt.Alignment.center,
      );

      // Cut line and spacing
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      // Print command
      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd == null) {
        _showError('Gagal membuat perintah print');
        return false;
      }

      await BluetoothPrintPlus.write(cmd);

      _showSuccess('Struk berhasil dicetak');
      return true;

    } catch (e) {
      print('Print receipt error: $e');
      _showError('Gagal mencetak struk: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  // Helper methods optimized for 58mm paper
  String _centerText(String text, int width) {
    if (text.length >= width) return text;
    int spaces = (width - text.length) ~/ 2;
    return (' ' * spaces) + text;
  }

  String _createSpacedLine(String left, String right, int width) {
    // For 58mm paper, we need tighter control
    int maxLeftLength = width - right.length - 1;
    String truncatedLeft = left.length > maxLeftLength
        ? left.substring(0, maxLeftLength - 2) + '..'
        : left;

    int totalUsed = truncatedLeft.length + right.length;
    int spaces = width - totalUsed;
    if (spaces < 1) spaces = 1;

    return '$truncatedLeft${' ' * spaces}$right';
  }

  String _createRightAlignedLine(String left, String right, int width) {
    // For quantity and price info
    int totalUsed = left.length + right.length;
    int spaces = width - totalUsed;
    if (spaces < 1) spaces = 1;

    return '$left${' ' * spaces}$right';
  }

  List<String> _splitText(String text, int maxWidth) {
    if (text.length <= maxWidth) return [text];

    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      if ((currentLine + ' ' + word).length <= maxWidth) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          // Word is longer than line width, force break
          lines.add(word.substring(0, maxWidth));
          currentLine = word.substring(maxWidth);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  String _formatCurrency(double amount) {
    // Simplified formatting for thermal printer
    String formatted = amount.toStringAsFixed(0);

    // Add thousand separators
    String result = '';
    int count = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = '.' + result;
      }
      result = formatted[i] + result;
      count++;
    }

    return 'Rp$result';
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

  @override
  void onClose() {
    // Cancel all subscriptions
    _isScanningSubscription?.cancel();
    _blueStateSubscription?.cancel();
    _connectStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();

    // Disconnect if connected
    disconnect();

    super.onClose();
  }
}
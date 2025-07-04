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
    String? footerNote,
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
      const String separator = '--------------------------------'; // Full width separator
      const String thinSeparator = '................................'; // Dashed line separator

      // Header - Store Info
      await _esc.text(content: ''); // Top spacing
      await _esc.text(
        content: _centerText(storeName, lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2, // Larger for store name
      );
      // Split and center address if too long
      List<String> addressLines = _splitText(storeAddress, lineWidth);
      for (String line in addressLines) {
        await _esc.text(content: _centerText(line, lineWidth), alignment: bt.Alignment.center);
      }
      await _esc.text(content: _centerText(storePhone, lineWidth), alignment: bt.Alignment.center);
      await _esc.text(content: ''); // Spacing after contact info

      await _esc.text(content: separator);

      // Transaction header
      await _esc.text(content: _centerText('NOTA TRANSAKSI', lineWidth), alignment: bt.Alignment.center, style: EscTextStyle.bold, fontSize: EscFontSize.size1);
      await _esc.text(content: thinSeparator); // Dashed line

      // Date, Time and Transaction ID with precise alignment
      final dateStr = DateFormat('dd-MM-yyyy').format(dateTime);
      final timeStr = DateFormat('HH:mm').format(dateTime);

      await _esc.text(content: _leftRightPadded('Tanggal:', dateStr, lineWidth));
      await _esc.text(content: _leftRightPadded('Waktu  :', timeStr, lineWidth));
      await _esc.text(content: _leftRightPadded('No.Ref :', transactionId, lineWidth));
      await _esc.text(content: ''); // Spacing

      await _esc.text(content: separator);

      // Items header
      await _esc.text(content: _centerText('ITEM PEMBELI', lineWidth), alignment: bt.Alignment.center, style: EscTextStyle.bold, fontSize: EscFontSize.size1);
      await _esc.text(content: thinSeparator); // Dashed line

      // Items list
      for (final item in items) {
        // Product name - might wrap, always bold
        List<String> nameLines = _splitText(item.productName.toUpperCase(), lineWidth);
        for (final line in nameLines) {
          await _esc.text(content: line, style: EscTextStyle.bold);
        }

        // Quantity, unit price and total price on next line, precisely aligned
        final qtyText = '${item.quantity} X ${_formatCurrency(item.unitPrice)}';
        final itemTotalText = _formatCurrency(item.totalPrice);
        await _esc.text(content: _leftRightPadded(qtyText, itemTotalText, lineWidth));
        await _esc.text(content: ''); // Spacing between items
      }

      await _esc.text(content: thinSeparator); // Dashed line

      // Summary section
      await _esc.text(content: _leftRightPadded('Subtotal', _formatCurrency(subtotal), lineWidth));

      if (adminFee > 0) {
        await _esc.text(content: _leftRightPadded('Admin', _formatCurrency(adminFee), lineWidth));
      }
      // if (tax > 0) {
      //   await _esc.text(content: _leftRightPadded('Pajak', _formatCurrency(tax), lineWidth));
      // }
      // if (shippingCost > 0) {
      //   await _esc.text(content: _leftRightPadded('Ongkir', _formatCurrency(shippingCost), lineWidth));
      // }
      await _esc.text(content: separator); // Full separator

      // TOTAL amount - larger and bold
      await _esc.text(
        content: _leftRightPadded('TOTAL', _formatCurrency(total), lineWidth),
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2, // Significantly larger for emphasis
      );

      await _esc.text(content: separator); // Full separator

      // Payment section
      await _esc.text(content: _leftRightPadded('Bayar', _formatCurrency(payment), lineWidth));
      await _esc.text(content: _leftRightPadded('Kembali', _formatCurrency(change), lineWidth));
      await _esc.text(content: ''); // Spacing

      await _esc.text(content: _centerText('Metode: $paymentMethod', lineWidth), alignment: bt.Alignment.center);

      await _esc.text(content: ''); // Spacing
      await _esc.text(
        content: _centerText('=== LUNAS ===', lineWidth), // Payment status
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size1,
      );

      await _esc.text(content: thinSeparator); // Dashed line before footer

      // Footer
      await _esc.text(content: _centerText('TERIMA KASIH', lineWidth), alignment: bt.Alignment.center, style: EscTextStyle.bold);

      if (footerNote != null && footerNote.isNotEmpty) {
        await _esc.text(content: '');
        List<String> footerLines = _splitText(footerNote, lineWidth);
        for (String line in footerLines) {
          await _esc.text(
            content: _centerText(line, lineWidth),
            alignment: bt.Alignment.center,
          );
        }
      } else {
        // Default footer if no custom note
        await _esc.text(
          content: _centerText('SELAMAT BERBELANJA', lineWidth),
          alignment: bt.Alignment.center,
        );
      }

      await _esc.text(content: _centerText('Terakhir diperbarui: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}', lineWidth), alignment: bt.Alignment.center);

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
  // --- Helper methods for precise text formatting ---

  // Centers text within lineWidth, ensuring exact width.
  String _centerText(String text, int lineWidth) {
    if (text.length >= lineWidth) {
      return text.substring(0, lineWidth); // Truncate if too long
    }
    final int pad = (lineWidth - text.length) ~/ 2;
    return text.padLeft(text.length + pad).padRight(lineWidth);
  }

  // Aligns left and right text precisely within lineWidth.
  // Truncates leftText if necessary, ensuring rightText is always visible.
  String _leftRightPadded(String leftText, String rightText, int lineWidth) {
    int maxLeftLength = lineWidth - rightText.length;
    if (maxLeftLength < 1) { // If no space for left text (or less than 1 char space)
      return rightText.padLeft(lineWidth); // Just print right text, right-aligned
    }

    String formattedLeft = leftText;
    if (leftText.length > maxLeftLength) {
      formattedLeft = leftText.substring(0, maxLeftLength - 1) + '.'; // Truncate with '.'
    }

    final int padding = lineWidth - formattedLeft.length - rightText.length;
    return formattedLeft + ' ' * (padding > 0 ? padding : 1) + rightText;
  }

  // Splits a long string into multiple lines based on maxWidth,
  // respecting word boundaries and handling very long words.
  List<String> _splitText(String text, int maxWidth) {
    if (text.length <= maxWidth) return [text];

    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      // If adding the word (and a space) makes the current line too long
      if ((currentLine + (currentLine.isEmpty ? '' : ' ') + word).length <= maxWidth) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        // Add current line to list if not empty
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        // Handle word that is itself longer than maxWidth
        if (word.length > maxWidth) {
          int start = 0;
          while (start < word.length) {
            int end = (start + maxWidth) > word.length ? word.length : (start + maxWidth);
            lines.add(word.substring(start, end));
            start = end;
          }
          currentLine = ''; // Reset current line after breaking long word
        } else {
          currentLine = word; // Start new line with the current word
        }
      }
    }
    // Add any remaining text
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  // Formats currency as "Rp" followed by amount with thousand separators, no decimals.
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID', // Indonesian locale for thousand separators
      symbol: 'Rp',     // Currency symbol
      decimalDigits: 0, // No decimal digits
    );
    // Remove the space that NumberFormat.currency might add after the symbol
    return formatter.format(amount).replaceAll('Rp ', 'Rp');
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
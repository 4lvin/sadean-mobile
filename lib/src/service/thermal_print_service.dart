import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:bluetooth_print_plus/src/enum_tool.dart' as bt;
import 'package:permission_handler/permission_handler.dart';
import 'package:sadean/src/models/transaction_model.dart';

/// Legacy thermal print service - kept for backward compatibility
/// Use ImprovedBluetoothPrintService for new implementations
@deprecated
class BluetoothPrintService {
  final EscCommand _esc = EscCommand();

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;

  StreamSubscription<List<BluetoothDevice>>? _scanSubscription;
  StreamSubscription<BlueState>? _connectionSubscription;

  bool _isConnected = false;

  /// Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status == PermissionStatus.granted);
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    devices.clear();

    // Request permissions first
    if (!await requestPermissions()) {
      throw Exception('Bluetooth permissions not granted');
    }

    await BluetoothPrintPlus.startScan(timeout: timeout);

    _scanSubscription?.cancel();
    _scanSubscription = BluetoothPrintPlus.scanResults.listen((results) {
      // Filter for thermal printers
      devices = results.where((device) =>
      device.name != null &&
          device.name!.isNotEmpty &&
          !device.name!.toLowerCase().contains('unknown') &&
          (device.name!.toLowerCase().contains('printer') ||
              device.name!.toLowerCase().contains('pos') ||
              device.name!.toLowerCase().contains('thermal'))
      ).toList();

      print("Found thermal printers: ${devices.length}");
    });

    await Future.delayed(timeout);
    await BluetoothPrintPlus.stopScan();
    await _scanSubscription?.cancel();
  }

  /// Select a device for connection
  void selectDevice(BluetoothDevice device) {
    selectedDevice = device;
  }

  /// Connect to the selected device
  Future<bool> connect() async {
    if (selectedDevice == null) return false;

    _isConnected = false;
    _connectionSubscription?.cancel();

    final completer = Completer<bool>();

    _connectionSubscription = BluetoothPrintPlus.blueState.listen((state) {
      if (state == BlueState.blueOn) {
        _isConnected = true;
        completer.complete(true);
      } else if (state == BlueState.blueOff) {
        _isConnected = false;
        completer.complete(false);
      }
    });

    try {
      await BluetoothPrintPlus.connect(selectedDevice!);
      return completer.future.timeout(Duration(seconds: 10), onTimeout: () => false);
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  /// Disconnect from the device
  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      _connectionSubscription?.cancel();
      _isConnected = false;
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  /// Check if device is connected
  bool get isConnected => _isConnected;

  /// Print a simple test page
  Future<bool> testPrint() async {
    if (!_isConnected) return false;

    try {
      await _esc.cleanCommand();

      await _esc.text(
        content: '=== TEST PRINT ===',
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: 'Printer successfully connected!',
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: DateTime.now().toString(),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');

      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
        return true;
      }
      return false;
    } catch (e) {
      print('Test print error: $e');
      return false;
    }
  }

  /// Print a transaction receipt
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
    if (!_isConnected) return false;

    try {
      await _esc.cleanCommand();
      const int lineWidth = 32;
      const String separator = '--------------------------------';

      // Header
      await _esc.text(
        content: _centerText(storeName, lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');
      await _esc.text(
        content: _centerText(storeAddress, lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(
        content: _centerText(storePhone, lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: separator);

      // Transaction info
      await _esc.text(
        content: _centerText('RECEIPT', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');

      final dateStr = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      await _esc.text(content: _createSpacedLine('Date', dateStr, lineWidth));
      await _esc.text(content: _createSpacedLine('Time', timeStr, lineWidth));
      await _esc.text(content: '');

      await _esc.text(
        content: _centerText('Transaction ID', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(
        content: _centerText(transactionId, lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: separator);

      // Items
      await _esc.text(content: 'ITEMS', style: EscTextStyle.bold);
      await _esc.text(content: '');

      for (var item in items) {
        String displayName = item.productName.length > lineWidth
            ? item.productName.substring(0, lineWidth - 3) + '...'
            : item.productName;
        await _esc.text(content: displayName);

        String qtyPrice = '${item.quantity}x${_formatCurrency(item.unitPrice)}';
        String totalStr = _formatCurrency(item.totalPrice);
        await _esc.text(content: _createSpacedLine(qtyPrice, totalStr, lineWidth));
        await _esc.text(content: '');
      }

      await _esc.text(content: separator);

      // Summary
      await _esc.text(content: _createSpacedLine('Subtotal', _formatCurrency(subtotal), lineWidth));

      if (adminFee > 0) {
        await _esc.text(content: _createSpacedLine('Admin Fee', _formatCurrency(adminFee), lineWidth));
      }

      await _esc.text(content: '');
      await _esc.text(
        content: _createSpacedLine('TOTAL', _formatCurrency(total), lineWidth),
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size1,
      );

      await _esc.text(content: separator);

      // Payment
      await _esc.text(content: _createSpacedLine('Payment', _formatCurrency(payment), lineWidth));
      await _esc.text(content: _createSpacedLine('Change', _formatCurrency(change), lineWidth));
      await _esc.text(content: '');

      await _esc.text(
        content: _centerText(paymentMethod.toUpperCase(), lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');

      await _esc.text(
        content: _centerText('PAID', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size1,
      );

      await _esc.text(content: '');
      await _esc.text(content: separator);

      // Footer
      await _esc.text(
        content: _centerText('THANK YOU', lineWidth),
        alignment: bt.Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(
        content: _centerText('FOR YOUR VISIT', lineWidth),
        alignment: bt.Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
        return true;
      }
      return false;
    } catch (e) {
      print('Print receipt error: $e');
      return false;
    }
  }

  // Helper methods
  String _centerText(String text, int width) {
    if (text.length >= width) return text;
    int spaces = (width - text.length) ~/ 2;
    return (' ' * spaces) + text + (' ' * spaces);
  }

  String _createSpacedLine(String left, String right, int width) {
    int space = width - left.length - right.length;
    if (space < 1) space = 1;
    return '$left${' ' * space}$right';
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await disconnect();
  }
}
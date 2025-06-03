import 'dart:async';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';

class BluetoothPrintService {
  final EscCommand _esc = EscCommand();

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;

  StreamSubscription<List<BluetoothDevice>>? _scanSubscription;
  StreamSubscription<BlueState>? _connectionSubscription;

  bool _isConnected = false;

  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    devices.clear();

    await BluetoothPrintPlus.startScan(timeout: timeout);

    _scanSubscription?.cancel();
    _scanSubscription = BluetoothPrintPlus.scanResults.listen((results) {
      devices = results;
    });

    await Future.delayed(timeout);
    await BluetoothPrintPlus.stopScan();
    await _scanSubscription?.cancel();
  }

  void selectDevice(BluetoothDevice device) {
    selectedDevice = device;
  }

  Future<bool> connect() async {
    if (selectedDevice == null) return false;

    _isConnected = false;

    _connectionSubscription?.cancel();
    _connectionSubscription = BluetoothPrintPlus.blueState.listen((state) {
      if (state == BlueState.blueOn) {
        _isConnected = true;
      } else if (state == BlueState.blueOff) {
        _isConnected = false;
      }
    });

    await BluetoothPrintPlus.connect(selectedDevice!);

    // Tunggu sampai status connected atau timeout 5 detik
    int wait = 0;
    while (!_isConnected && wait < 50) {
      await Future.delayed(Duration(milliseconds: 100));
      wait++;
    }

    return _isConnected;
  }

  Future<void> disconnect() async {
    await BluetoothPrintPlus.disconnect();
    _connectionSubscription?.cancel();
    _isConnected = false;
  }

  Future<void> printTransaction({
    required String title,
    required List<String> items,
    required String total,
    required String footer,
  }) async {
    if (selectedDevice == null) {
      throw Exception('No Bluetooth device selected');
    }

    final connected = await connect();
    if (!connected) {
      throw Exception('Failed to connect to Bluetooth device');
    }

    await _esc.cleanCommand();

    await _esc.text(content: title, fontSize: EscFontSize.size2);
    await _esc.text(content: '----------------------');

    for (var item in items) {
      await _esc.text(content: item);
    }

    await _esc.text(content: '----------------------');
    await _esc.text(content: 'Total:         $total');
    await _esc.text(content: footer);

    final cmd = await _esc.getCommand();
    if (cmd != null) {
      await BluetoothPrintPlus.write(cmd);
    }
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await disconnect();
  }
}

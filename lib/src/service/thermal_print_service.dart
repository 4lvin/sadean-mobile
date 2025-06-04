import 'dart:async';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sadean/src/models/transaction_model.dart';

class BluetoothPrintService {
  final EscCommand _esc = EscCommand();

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;

  StreamSubscription<List<BluetoothDevice>>? _scanSubscription;
  StreamSubscription<BlueState>? _connectionSubscription;

  bool _isConnected = false;

  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    devices.clear();

    // Minta izin BLE
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    await BluetoothPrintPlus.startScan(timeout: timeout);

    _scanSubscription?.cancel();
    _scanSubscription = BluetoothPrintPlus.scanResults.listen((results) {
      devices = results;
      print("Found devices: ${devices.length}");
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

    await BluetoothPrintPlus.connect(selectedDevice!);

    // Tunggu maksimal 5 detik
    return completer.future.timeout(Duration(seconds: 5), onTimeout: () => false);
  }

  Future<void> disconnect() async {
    await BluetoothPrintPlus.disconnect();
    _connectionSubscription?.cancel();
    _isConnected = false;
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await disconnect();
  }
}

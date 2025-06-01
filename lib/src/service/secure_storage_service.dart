import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

// ===========================
// BASE SECURE STORAGE SERVICE
// ===========================
class SecureStorageService extends GetxService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    // iOptions: IOSOptions(
    //   accessibility: IOSAccessibility.first_unlock_this_device,
    // ),
  );

  // Generic methods untuk CRUD operations
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    await _storage.write(key: key, value: jsonEncode(data));
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> data) async {
    await _storage.write(key: key, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getData(String key) async {
    final String? data = await _storage.read(key: key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<List<Map<String, dynamic>>> getList(String key) async {
    final String? data = await _storage.read(key: key);
    if (data == null) return [];
    final List<dynamic> jsonData = jsonDecode(data);
    return jsonData.cast<Map<String, dynamic>>();
  }

  Future<void> deleteData(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Convert image to Base64
  Future<String> imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  // Convert Base64 to image bytes
  Uint8List? base64ToImage(String? base64String) {
    if (base64String == null) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64 image: $e');
      return null;
    }
  }
}
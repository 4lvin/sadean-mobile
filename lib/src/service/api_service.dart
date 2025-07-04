import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'api_constant.dart';
import 'app_exception.dart';

class ApiProvider extends GetxService {
  // Timeout duration for API calls
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Headers for API calls
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Secure storage instance
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        throw Exception('Email dan password tidak boleh kosong');
      }

      // Prepare request body
      final body = {
        "email": email.trim(),
        "password": password,
      };

      print('Login request to: ${ApiConstants.login}');
      print('Request body: ${jsonEncode(body)}');

      // Make API call
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Process response
      final processedResponse = _processResponse(response);

      // Parse JSON response
      final Map<String, dynamic> jsonResponse = jsonDecode(processedResponse);

      return jsonResponse;

    } on SocketException catch (e) {
      print('SocketException: $e');
      throw Exception('No Internet connection');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      throw Exception('API not responded in time');
    } on FormatException catch (e) {
      print('FormatException: $e');
      throw Exception('Invalid response format');
    } on BadRequestException catch (e) {
      print('BadRequestException: $e');
      throw Exception(e.message);
    } on UnAuthorizedException catch (e) {
      print('UnAuthorizedException: $e');
      throw Exception('Unauthorized access');
    } on FetchDataException catch (e) {
      print('FetchDataException: $e');
      throw Exception(e.message);
    } catch (e) {
      print('Unexpected error in login: $e');
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
    }
  }

  // Check subscription method
  Future<Map<String, dynamic>> checkSubscribe() async {
    try {
      // Get token from secure storage
      final token = await _storage.read(key: "access_token");

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia');
      }

      print("Token: $token");

      // Prepare headers with authorization
      final headers = {
        ..._headers,
        'Authorization': "Bearer $token",
      };

      print('CheckSubscribe request to: ${ApiConstants.checkSubscribe}');

      // Make API call
      final response = await http.get(
        Uri.parse(ApiConstants.checkSubscribe),
        headers: headers,
      ).timeout(_timeoutDuration);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Process response
      final processedResponse = _processResponse(response);

      // Parse JSON response
      final Map<String, dynamic> jsonResponse = jsonDecode(processedResponse);

      return jsonResponse;

    } on SocketException catch (e) {
      print('SocketException: $e');
      throw Exception('No Internet connection');
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      throw Exception('API not responded in time');
    } on FormatException catch (e) {
      print('FormatException: $e');
      throw Exception('Invalid response format');
    } on BadRequestException catch (e) {
      print('BadRequestException: $e');
      throw Exception(e.message);
    } on UnAuthorizedException catch (e) {
      print('UnAuthorizedException: $e');
      throw Exception('Unauthorized access');
    } on FetchDataException catch (e) {
      print('FetchDataException: $e');
      throw Exception(e.message);
    } catch (e) {
      print('Unexpected error in checkSubscribe: $e');
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> uploadSqliteBackup(File backupFile) async {
    try {
      final token = await _storage.read(key: "access_token");
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak tersedia. Tidak dapat mengunggah file.');
      }

      final uri = Uri.parse(ApiConstants.backupUpload);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      // Attach the file to the request with the field name 'sql_file'
      request.files.add(await http.MultipartFile.fromPath(
        'sql_file', // This must match the field name expected by the backend
        backupFile.path,
        filename: backupFile.path.split('/').last, // Use the actual file name
        // contentType: MediaType('application', 'x-sqlite3'), // Optional: specify MIME type
      ));

      print('Uploading SQLite backup file to: ${ApiConstants.backupUpload}');
      print('File path: ${backupFile.path}');

      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload Backup Response status: ${response.statusCode}');
      print('Upload Backup Response body: ${response.body}');

      return jsonDecode(_processResponse(response));
    } on SocketException catch (e) {
      print('SocketException (Upload SQLite Backup): $e');
      throw Exception('No Internet connection');
    } on TimeoutException catch (e) {
      print('TimeoutException (Upload SQLite Backup): $e');
      throw Exception('API not responded in time for backup upload');
    } on FormatException catch (e) {
      print('FormatException (Upload SQLite Backup): $e');
      throw Exception('Invalid response format for backup upload');
    } on BadRequestException catch (e) {
      print('BadRequestException (Upload SQLite Backup): $e');
      throw Exception(e.message);
    } on UnAuthorizedException catch (e) {
      print('UnAuthorizedException (Upload SQLite Backup): $e');
      throw Exception('Unauthorized access for backup upload');
    } on FetchDataException catch (e) {
      print('FetchDataException (Upload SQLite Backup): $e');
      throw Exception(e.message);
    } catch (e) {
      print('Unexpected error in uploadSqliteBackup: $e');
      throw Exception('Terjadi kesalahan tidak terduga saat mengunggah backup: ${e.toString()}');
    }
  }


  // Process HTTP response
  String _processResponse(http.Response response) {
    final String responseBody = utf8.decode(response.bodyBytes);
    final String url = response.request?.url.toString() ?? 'Unknown URL';

    print('Processing response - Status: ${response.statusCode}, URL: $url');

    switch (response.statusCode) {
      case 200:
      case 201:
      // Success responses
        return responseBody;

      case 400:
      // Bad request - return response body to handle in controller
        return responseBody;

      case 401:
      // Unauthorized - return response body to handle in controller
        return responseBody;

      case 403:
      // Forbidden
        throw UnAuthorizedException(responseBody, url);

      case 404:
      // Not found - return response body to handle in controller
        return responseBody;

      case 422:
      // Validation error
        throw BadRequestException(responseBody, url);

      case 500:
      case 502:
      case 503:
      // Server errors
        throw BadRequestException('Server error occurred', url);

      default:
      // Other errors
        throw FetchDataException(
          'Error occurred with code: ${response.statusCode}',
          url,
        );
    }
  }

  // Helper method to get authorization headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: "access_token");
    return {
      ..._headers,
      if (token != null) 'Authorization': "Bearer $token",
    };
  }

  // Method to clear stored token (for logout)
  Future<void> clearToken() async {
    await _storage.delete(key: "access_token");
    await _storage.delete(key: "token_type");
  }
}
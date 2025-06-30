// lib/src/service/auth_service.dart

import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthService extends GetxService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _isLoggedInKey = 'is_logged_in';

  // Current user observable
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString accessToken = ''.obs;
  final RxString tokenType = 'Bearer'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  // Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final userData = await _storage.read(key: _userKey);
      final token = await _storage.read(key: _tokenKey);
      final tokenTypeValue = await _storage.read(key: _tokenTypeKey);

      if (userData != null && token != null) {
        final userJson = jsonDecode(userData);
        currentUser.value = User.fromJson(userJson);
        accessToken.value = token;
        tokenType.value = tokenTypeValue ?? 'Bearer';
      }
    } catch (e) {
      print('Error loading user data: $e');
      await clearUserData();
    }
  }

  // Save user data and token
  Future<void> saveUserData({
    required User user,
    required String accessToken,
    required String tokenType,
  }) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      await _storage.write(key: _tokenKey, value: accessToken);
      await _storage.write(key: _tokenTypeKey, value: tokenType);
      await _storage.write(key: _isLoggedInKey, value: 'true');

      // Update observables
      currentUser.value = user;
      this.accessToken.value = accessToken;
      this.tokenType.value = tokenType;
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('Failed to save user data');
    }
  }

  // Clear user data (logout)
  Future<void> clearUserData() async {
    try {
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _tokenTypeKey);
      await _storage.delete(key: _isLoggedInKey);

      // Clear observables
      currentUser.value = null;
      accessToken.value = '';
      tokenType.value = 'Bearer';
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final isLoggedInValue = await _storage.read(key: _isLoggedInKey);
      final token = await _storage.read(key: _tokenKey);

      return isLoggedInValue == 'true' &&
          token != null &&
          token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get authorization header
  String get authorizationHeader {
    if (accessToken.value.isNotEmpty) {
      return '${tokenType.value} ${accessToken.value}';
    }
    return '';
  }

  // Update user profile
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(updatedUser.toJson()));
      currentUser.value = updatedUser;
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Clear user data
      await clearUserData();

      // Navigate to login page
      Get.offAllNamed('/login');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Check if token is expired (basic check)
  bool get isTokenExpired {
    // TODO: Implement token expiration check based on your API's token structure
    // This is a basic implementation
    return accessToken.value.isEmpty;
  }

  // Refresh token (if your API supports it)
  Future<bool> refreshToken() async {
    // TODO: Implement token refresh logic based on your API
    // This is a placeholder
    try {
      // Make API call to refresh token
      // Update stored token if successful
      return true;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // Get user permissions (based on role)
  List<String> get userPermissions {
    if (currentUser.value == null) return [];

    switch (currentUser.value!.role.toLowerCase()) {
      case 'admin':
        return ['read', 'write', 'delete', 'manage_users', 'view_reports'];
      case 'member':
        return ['read', 'write'];
      default:
        return ['read'];
    }
  }

  // Check user permission
  bool hasPermission(String permission) {
    return userPermissions.contains(permission);
  }

  // Check if user is admin
  bool get isAdmin {
    return currentUser.value?.isAdmin ?? false;
  }

  // Check if user is member
  bool get isMember {
    return currentUser.value?.isMember ?? false;
  }
}
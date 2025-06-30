// lib/src/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';
import '../routers/constant.dart';

class LoginController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final AuthService _authService = Get.put(AuthService());

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAutoLogin();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Check if user is already logged in
  Future<void> _checkAutoLogin() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Navigate to main page if already logged in
        Get.offAllNamed(mainRoute);
      }
    } catch (e) {
      print('Auto login check failed: $e');
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Validate form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  // Login method
  Future<void> login() async {
    if (!validateForm()) {
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiProvider.login(
        emailController.text.trim(),
        passwordController.text,
      );

      // Parse response
      if (response['status'] == true) {
        final userData = response['data'];
        final accessToken = response['access_token'];
        final tokenType = response['token_type'];

        // Create user model
        final user = User.fromJson(userData);

        // Save user data and token
        await _authService.saveUserData(
          user: user,
          accessToken: accessToken,
          tokenType: tokenType,
        );

        // Clear form
        _clearForm();

        // Show success message
        Get.snackbar(
          'Login Berhasil',
          'Selamat datang, ${user.name}!',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 2),
        );

        // Navigate to main page
        Get.offAllNamed(mainRoute);
      } else {
        // Handle login failure
        final message = response['message'] ?? 'Login gagal';
        _showError(message);
      }
    } catch (e) {
      print('Login error: $e');
      _showError('Terjadi kesalahan saat login. Silakan coba lagi.');
    } finally {
      isLoading.value = false;
    }
  }

  // Show error message
  void _showError(String message) {
    Get.snackbar(
      'Login Gagal',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 3),
    );
  }

  // Clear form
  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    isPasswordVisible.value = false;
  }

  // Forgot password
  void forgotPassword() {
    // TODO: Implement forgot password functionality
    Get.snackbar(
      'Info',
      'Silahkan hubungi admin untuk melakukan reset password',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  // Sign up navigation
  void navigateToSignUp() {
    // TODO: Implement sign up navigation
    Get.snackbar(
      'Info',
      'Fitur pendaftaran akan segera tersedia',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }
}
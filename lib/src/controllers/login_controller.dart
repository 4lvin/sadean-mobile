// lib/src/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
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

      // Parse response - handle both Map and String responses
      Map<String, dynamic> responseData;
      if (response is String) {
        // If response is already a JSON string, parse it
        responseData = {};
        try {
          responseData = Map<String, dynamic>.from(response as Map);
        } catch (e) {
          // If parsing fails, treat as error
          _showError('Response format tidak valid');
          return;
        }
      } else if (response is Map<String, dynamic>) {
        responseData = response;
      } else {
        _showError('Response format tidak valid');
        return;
      }

      // Check if login was successful
      if (responseData['status'] == true || responseData['success'] == true) {
        // Handle successful login
        await _handleSuccessfulLogin(responseData);
      } else {
        // Handle login failure
        final message = responseData['message'] ??
            responseData['error'] ??
            'Login gagal';
        _showError(message);
      }
    } catch (e) {
      print('Login error: $e');
      String errorMessage = 'Terjadi kesalahan saat login. Silakan coba lagi.';

      // Handle specific error types
      if (e.toString().contains('No Internet connection')) {
        errorMessage = 'Tidak ada koneksi internet';
      } else if (e.toString().contains('API not responded in time')) {
        errorMessage = 'Server tidak merespons, coba lagi nanti';
      } else if (e.toString().contains('Unauthorized') || e.toString().contains('401')) {
        errorMessage = 'Email atau password salah';
      }

      _showError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Handle successful login
  Future<void> _handleSuccessfulLogin(Map<String, dynamic> responseData) async {
    try {
      // Extract user data and tokens
      final userData = responseData['data'] ?? responseData['user'];
      final accessToken = responseData['access_token'] ?? responseData['token'];
      final tokenType = responseData['token_type'] ?? 'Bearer';

      if (userData == null || accessToken == null) {
        _showError('Data login tidak lengkap');
        return;
      }

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
        snackPosition: SnackPosition.TOP,
      );

      // Navigate to main page
      Get.offAllNamed(mainRoute);
    } catch (e) {
      print('Handle successful login error: $e');
      _showError('Gagal memproses data login');
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
      snackPosition: SnackPosition.TOP,
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
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  void navigateToSignUp() async {
    const phoneNumber = '6285708607452'; // Nomor tanpa '+' atau '0' di depan
    const message = 'Hai min, info lebih lanjut cara dapat akun dong.';
    final encodedMessage = Uri.encodeComponent(message);

    // URL universal untuk WhatsApp
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

    try {
      // Coba luncurkan URL
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Jika gagal, tampilkan dialog yang lebih jelas
        _showWhatsappErrorDialog();
      }
    } catch (e) {
      _showWhatsappErrorDialog();
    }
  }

  /// Dialog error yang lebih informatif
  void _showWhatsappErrorDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Gagal Membuka WhatsApp'),
        content: const Text(
          'Aplikasi WhatsApp tidak ditemukan di perangkat Anda. '
              'Pastikan WhatsApp sudah terpasang untuk melanjutkan pendaftaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
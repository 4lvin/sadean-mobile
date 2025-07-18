import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse to int and format with thousand separators
    int value = int.parse(digitsOnly);
    String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyHelper {
  static final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  // Convert formatted string to double
  static double parseFromFormatted(String formattedText) {
    if (formattedText.isEmpty) return 0.0;
    String digitsOnly = formattedText.replaceAll('.', '').replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.isEmpty ? 0.0 : double.parse(digitsOnly);
  }

  // Format double to currency string without Rp prefix
  static String formatToInput(double value) {
    if (value == 0) return '';
    return _formatter.format(value.toInt());
  }

  // Format for display with Rp prefix
  static String formatToDisplay(double value) {
    return 'Rp ${_formatter.format(value.toInt())}';
  }
}
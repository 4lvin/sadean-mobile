// lib/src/controllers/income_expense_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/income_expense_model.dart';
import '../service/income_expense_service.dart';

class IncomeExpenseController extends GetxController {
  final IncomeExpenseService _service = Get.find<IncomeExpenseService>();

  // Observables
  final RxList<IncomeExpense> allRecords = <IncomeExpense>[].obs;
  final RxList<IncomeExpense> incomeRecords = <IncomeExpense>[].obs;
  final RxList<IncomeExpense> expenseRecords = <IncomeExpense>[].obs;
  final RxBool isLoading = false.obs;

  // Form controllers
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  // Form observables
  final RxString selectedType = 'expense'.obs;
  final RxString selectedPaymentMethod = 'cash'.obs;
  final RxBool useCustomDateTime = false.obs;
  final Rx<DateTime> selectedDateTime = DateTime.now().obs;

  // Statistics
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpense = 0.0.obs;
  final RxDouble balance = 0.0.obs;

  // Filter
  final RxString filterType = 'all'.obs; // 'all', 'income', 'expense'
  final Rx<DateTime?> filterStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEndDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchAllRecords();
    fetchStatistics();
  }

  @override
  void onClose() {
    amountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Fetch all records
  Future<void> fetchAllRecords() async {
    isLoading.value = true;

    try {
      final all = await _service.getAllRecords();
      final income = await _service.getAllIncome();
      final expenses = await _service.getAllExpenses();

      allRecords.assignAll(all);
      incomeRecords.assignAll(income);
      expenseRecords.assignAll(expenses);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch statistics
  Future<void> fetchStatistics() async {
    try {
      final stats = await _service.getStatistics(
        startDate: filterStartDate.value,
        endDate: filterEndDate.value,
      );

      totalIncome.value = stats['totalIncome'] ?? 0.0;
      totalExpense.value = stats['totalExpense'] ?? 0.0;
      balance.value = stats['balance'] ?? 0.0;
    } catch (e) {
      print('Error fetching statistics: $e');
    }
  }

  // Reset form
  void resetForm() {
    amountController.clear();
    notesController.clear();
    selectedType.value = 'expense';
    selectedPaymentMethod.value = 'cash';
    useCustomDateTime.value = false;
    selectedDateTime.value = DateTime.now();
  }

  // Validate form
  bool validateForm() {
    if (amountController.text.isEmpty) {
      Get.snackbar('Error', 'Jumlah wajib diisi');
      return false;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Jumlah harus berupa angka positif');
      return false;
    }

    return true;
  }

  // Save record
  Future<void> saveRecord() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      final amount = double.parse(amountController.text);
      final date = useCustomDateTime.value ? selectedDateTime.value : DateTime.now();

      await _service.addRecord(
        type: selectedType.value,
        amount: amount,
        paymentMethod: selectedPaymentMethod.value,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        date: date,
      );

      await fetchAllRecords();
      await fetchStatistics();
      resetForm();

      Get.back();
      Get.snackbar(
        'Sukses',
        '${selectedType.value == 'income' ? 'Pendapatan' : 'Pengeluaran'} berhasil ditambahkan',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update record
  Future<void> updateRecord(String id) async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      final amount = double.parse(amountController.text);
      final date = useCustomDateTime.value ? selectedDateTime.value : DateTime.now();

      await _service.updateRecord(
        id: id,
        amount: amount,
        paymentMethod: selectedPaymentMethod.value,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        date: date,
      );

      await fetchAllRecords();
      await fetchStatistics();
      resetForm();

      Get.back();
      Get.snackbar('Sukses', 'Data berhasil diperbarui');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete record
  Future<void> deleteRecord(String id) async {
    try {
      isLoading.value = true;
      await _service.deleteRecord(id);
      await fetchAllRecords();
      await fetchStatistics();
      Get.snackbar('Sukses', 'Data berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Show form dialog
  void showFormDialog({IncomeExpense? record}) {
    if (record != null) {
      // Edit mode
      selectedType.value = record.type;
      amountController.text = record.amount.toString();
      notesController.text = record.notes ?? '';
      selectedPaymentMethod.value = record.paymentMethod;
      selectedDateTime.value = record.date;
      useCustomDateTime.value = true;
    } else {
      // Create mode
      resetForm();
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record != null ? 'Edit Data' : 'Tambah Data',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Type selection (only for new record)
                if (record == null) ...[
                  const Text(
                    'Jenis',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Pengeluaran'),
                          value: 'expense',
                          groupValue: selectedType.value,
                          onChanged: (value) => selectedType.value = value!,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Pendapatan'),
                          value: 'income',
                          groupValue: selectedType.value,
                          onChanged: (value) => selectedType.value = value!,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                ],

                // Date & Time Toggle
                Obx(() => SwitchListTile(
                  title: const Text('Atur Tanggal & Waktu'),
                  subtitle: Text(
                    useCustomDateTime.value
                        ? DateFormat('dd MMM yyyy, HH:mm').format(selectedDateTime.value)
                        : 'Gunakan waktu saat ini',
                    style: TextStyle(
                      color: useCustomDateTime.value ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  value: useCustomDateTime.value,
                  onChanged: (value) => useCustomDateTime.value = value,
                  contentPadding: EdgeInsets.zero,
                )),

                // Date & Time Pickers
                if (useCustomDateTime.value) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDateTime.value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(),
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            DateFormat('HH:mm').format(selectedDateTime.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Amount
                const Text(
                  'Nominal',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                ),

                const SizedBox(height: 16),

                // Payment Method
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedPaymentMethod.value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                    DropdownMenuItem(value: 'card', child: Text('Kartu')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (value) => selectedPaymentMethod.value = value!,
                )),

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Tambahkan catatan...',
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () => record != null
                            ? updateRecord(record.id)
                            : saveRecord(),
                        child: isLoading.value
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(record != null ? 'Perbarui' : 'Simpan'),
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDateTime.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      selectedDateTime.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        selectedDateTime.value.hour,
        selectedDateTime.value.minute,
      );
    }
  }

  // Select time
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime.value),
    );

    if (picked != null) {
      selectedDateTime.value = DateTime(
        selectedDateTime.value.year,
        selectedDateTime.value.month,
        selectedDateTime.value.day,
        picked.hour,
        picked.minute,
      );
    }
  }

  // Format currency
  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Get filtered records
  List<IncomeExpense> get filteredRecords {
    List<IncomeExpense> records = allRecords;

    // Filter by type
    if (filterType.value == 'income') {
      records = incomeRecords;
    } else if (filterType.value == 'expense') {
      records = expenseRecords;
    }

    // Filter by date range
    if (filterStartDate.value != null && filterEndDate.value != null) {
      records = records.where((record) {
        return record.date.isAfter(filterStartDate.value!.subtract(const Duration(days: 1))) &&
            record.date.isBefore(filterEndDate.value!.add(const Duration(days: 1)));
      }).toList();
    }

    return records;
  }

  // Apply filters
  void applyFilters() async {
    await fetchAllRecords();
    await fetchStatistics();
  }

  // Clear filters
  void clearFilters() {
    filterType.value = 'all';
    filterStartDate.value = null;
    filterEndDate.value = null;
    applyFilters();
  }

  // Get payment method display name
  String getPaymentMethodDisplay(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      case 'card':
        return 'Kartu';
      case 'other':
        return 'Lainnya';
      default:
        return method;
    }
  }
}
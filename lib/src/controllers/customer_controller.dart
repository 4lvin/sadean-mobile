// lib/src/controllers/customer_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/customer_model.dart';
import '../service/customer_service.dart';

class CustomerController extends GetxController {
  final CustomerService _service = Get.find<CustomerService>();

  // Observables
  final RxList<Customer> customers = <Customer>[].obs;
  final RxList<Customer> filteredCustomers = <Customer>[].obs;
  final RxList<CustomerTransaction> customerTransactions = <CustomerTransaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Selected customer for detail view
  final Rx<Customer?> selectedCustomer = Rx<Customer?>(null);

  // Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final barcodeController = TextEditingController();
  final addressController = TextEditingController();

  // Payment form controllers
  final paymentAmountController = TextEditingController();
  final paymentNotesController = TextEditingController();
  final RxString selectedPaymentMethod = 'cash'.obs;

  // Transaction tab index
  final RxInt selectedTabIndex = 0.obs; // 0: Riwayat, 1: Transaksi

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();

    // Listen to search changes
    debounce(searchQuery, _performSearch, time: const Duration(milliseconds: 500));
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    barcodeController.dispose();
    addressController.dispose();
    paymentAmountController.dispose();
    paymentNotesController.dispose();
    super.onClose();
  }

  // Fetch all customers
  Future<void> fetchCustomers() async {
    isLoading.value = true;
    try {
      final customerList = await _service.getAllCustomers();
      customers.assignAll(customerList);
      _performSearch(searchQuery.value);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data pelanggan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Search customers
  void _performSearch(String query) {
    if (query.isEmpty) {
      filteredCustomers.assignAll(customers);
    } else {
      filteredCustomers.assignAll(
        customers.where((customer) =>
        customer.name.toLowerCase().contains(query.toLowerCase()) ||
            (customer.phoneNumber?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (customer.email?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList(),
      );
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    _performSearch('');
  }

  // Reset form
  void resetForm() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    barcodeController.clear();
    addressController.clear();
  }

  // Validate form
  bool validateForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Nama pelanggan wajib diisi');
      return false;
    }
    return true;
  }

  // Add customer
  Future<void> addCustomer() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      await _service.addCustomer(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
        barcode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
        address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
      );

      await fetchCustomers();
      resetForm();
      Get.back();

      Get.snackbar(
        'Berhasil',
        'Pelanggan berhasil ditambahkan',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Update customer
  Future<void> updateCustomer(String customerId) async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      await _service.updateCustomer(
        id: customerId,
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
        barcode: barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
        address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
      );

      await fetchCustomers();

      // Update selected customer if it's being viewed
      if (selectedCustomer.value?.id == customerId) {
        final updatedCustomer = await _service.getCustomerById(customerId);
        selectedCustomer.value = updatedCustomer;
      }

      resetForm();
      Get.back();

      Get.snackbar('Berhasil', 'Data pelanggan berhasil diperbarui');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      isLoading.value = true;

      await _service.deleteCustomer(customerId);
      await fetchCustomers();

      Get.snackbar('Berhasil', 'Pelanggan berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Load customer for editing
  void loadCustomerForEdit(Customer customer) {
    nameController.text = customer.name;
    phoneController.text = customer.phoneNumber ?? '';
    emailController.text = customer.email ?? '';
    barcodeController.text = customer.barcode ?? '';
    addressController.text = customer.address ?? '';
  }

  // Select customer for detail view
  Future<void> selectCustomer(Customer customer) async {
    selectedCustomer.value = customer;
    await fetchCustomerTransactions(customer.id);
  }

  // Fetch customer transactions
  Future<void> fetchCustomerTransactions(String customerId) async {
    try {
      final transactions = await _service.getCustomerTransactions(customerId);
      customerTransactions.assignAll(transactions);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat riwayat transaksi: $e');
    }
  }

  // Set tab index
  void setTabIndex(int index) {
    selectedTabIndex.value = index;
  }

  // Get filtered transactions by type
  List<CustomerTransaction> get filteredTransactions {
    if (selectedTabIndex.value == 0) {
      // Riwayat: Semua transaksi
      return customerTransactions;
    } else {
      // Transaksi: Hanya invoice
      return customerTransactions.where((t) => t.isInvoice).toList();
    }
  }

  // Reset payment form
  void resetPaymentForm() {
    paymentAmountController.clear();
    paymentNotesController.clear();
    selectedPaymentMethod.value = 'cash';
  }

  // Validate payment form
  bool validatePaymentForm() {
    final amount = double.tryParse(paymentAmountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Masukkan nominal pembayaran yang valid');
      return false;
    }
    return true;
  }

  // Add payment
  Future<void> addPayment(String customerId) async {
    if (!validatePaymentForm()) return;

    try {
      isLoading.value = true;

      final amount = double.parse(paymentAmountController.text);

      await _service.addCustomerTransaction(
        customerId: customerId,
        type: 'payment',
        amount: amount,
        paymentMethod: selectedPaymentMethod.value,
        notes: paymentNotesController.text.trim().isNotEmpty ? paymentNotesController.text.trim() : null,
      );

      // Refresh customer data
      final updatedCustomer = await _service.getCustomerById(customerId);
      selectedCustomer.value = updatedCustomer;

      // Refresh transactions
      await fetchCustomerTransactions(customerId);

      // Refresh customer list
      await fetchCustomers();

      resetPaymentForm();
      Get.back();

      Get.snackbar(
        'Berhasil',
        'Pembayaran berhasil dicatat',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Add invoice
  Future<void> addInvoice(String customerId, double amount, {String? notes}) async {
    try {
      await _service.addCustomerTransaction(
        customerId: customerId,
        type: 'invoice',
        amount: amount,
        notes: notes,
      );

      // Refresh customer data
      final updatedCustomer = await _service.getCustomerById(customerId);
      selectedCustomer.value = updatedCustomer;

      // Refresh transactions
      await fetchCustomerTransactions(customerId);

      // Refresh customer list
      await fetchCustomers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambah tagihan: $e');
      rethrow;
    }
  }

  // Show customer form dialog
  void showCustomerForm({Customer? customer}) {
    if (customer != null) {
      loadCustomerForEdit(customer);
    } else {
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
                      customer != null ? 'Edit Pelanggan' : 'Tambah Pelanggan',
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

                // Name field (required)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelanggan *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone field
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '08xxxxxxxxxx',
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // Email field
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'contoh@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Barcode field
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                    hintText: 'Scan atau ketik barcode',
                  ),
                ),

                const SizedBox(height: 16),

                // Address field
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'Alamat lengkap pelanggan',
                  ),
                  maxLines: 3,
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
                            : () => customer != null
                            ? updateCustomer(customer.id)
                            : addCustomer(),
                        child: isLoading.value
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(customer != null ? 'Perbarui' : 'Simpan'),
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

  // Show payment form dialog
  void showPaymentForm(Customer customer) {
    resetPaymentForm();

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
                    const Text(
                      'Terima Pembayaran',
                      style: TextStyle(
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

                // Customer info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pelanggan: ${customer.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saldo Sekarang:',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            formatCurrency(customer.balance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: customer.balance > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        final paymentAmount = double.tryParse(paymentAmountController.text) ?? 0;
                        final newBalance = customer.balance - paymentAmount;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saldo Akhir:',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              formatCurrency(newBalance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: newBalance > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment method
                const Text(
                  'Jenis Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedPaymentMethod.value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                    DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                    DropdownMenuItem(value: 'card', child: Text('Kartu')),
                  ],
                  onChanged: (value) => selectedPaymentMethod.value = value!,
                )),

                const SizedBox(height: 16),

                // Payment amount
                const Text(
                  'Nominal Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: paymentAmountController,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => update(), // Trigger UI update for balance calculation
                ),

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: paymentNotesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Catatan pembayaran...',
                  ),
                  maxLines: 2,
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
                      child: Obx(() {
                        final amount = double.tryParse(paymentAmountController.text) ?? 0;
                        final isEnabled = amount > 0 && !isLoading.value;

                        return ElevatedButton(
                          onPressed: isEnabled
                              ? () => addPayment(customer.id)
                              : null,
                          child: isLoading.value
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Simpan'),
                        );
                      }),
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

  // Format currency
  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Format date
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  // Get payment method display
  String getPaymentMethodDisplay(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      case 'card':
        return 'Kartu';
      default:
        return method;
    }
  }
}
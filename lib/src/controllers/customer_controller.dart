// lib/src/controllers/customer_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sadean/src/controllers/transaction_controller.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../service/customer_service.dart';
import '../service/transaction_service.dart';
import 'history_controller.dart';

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

      // Update selected customer if it's being viewed
      if (selectedCustomer.value?.id == customerId) {
        final updatedCustomer = await _service.getCustomerById(customerId);
        selectedCustomer.value = updatedCustomer;
      }
      await _refreshAllRelatedData();
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
      await _refreshAllRelatedData();

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
  Future<void> addPayment(String customerId, {double? amount, String? paymentMethod, String? notes, String? transactionId}) async {
    if (amount == null) {
      if (!validatePaymentForm()) return;
      amount = double.parse(paymentAmountController.text);
      paymentMethod = selectedPaymentMethod.value;
      notes = paymentNotesController.text.trim().isNotEmpty ? paymentNotesController.text.trim() : null;
    }

    try {
      isLoading.value = true;
      await _service.addCustomerTransaction(
        customerId: customerId,
        type: 'payment',
        amount: amount,
        paymentMethod: paymentMethod ?? 'cash',
        notes: notes,
      );

      // Refresh customer data
      final updatedCustomer = await _service.getCustomerById(customerId);
      selectedCustomer.value = updatedCustomer;

      await _refreshAllRelatedData();

      // Refresh transactions
      await fetchCustomerTransactions(customerId);

      await _updateRelatedTransactions(customerId, amount);
      // Refresh customer list
      await fetchCustomers();

      if (amount == double.tryParse(paymentAmountController.text)) {
        resetPaymentForm();
        Get.back();
      }

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

  Future<void> _updateRelatedTransactions(String customerId, double paymentAmount) async {
    try {
      // Get customer transactions to find pending invoices
      final customerTransactions = await _service.getCustomerTransactions(customerId);

      // Find pending invoices (transactions with notes containing 'Transaksi:')
      final pendingInvoices = customerTransactions
          .where((t) => t.isInvoice && t.notes != null && t.notes!.contains('Transaksi:'))
          .toList();

      if (pendingInvoices.isEmpty) return;

      // Sort by date (oldest first) to pay off oldest debts first
      pendingInvoices.sort((a, b) => a.date.compareTo(b.date));

      double remainingPayment = paymentAmount;

      for (final invoice in pendingInvoices) {
        if (remainingPayment <= 0) break;

        // Extract transaction ID from notes
        final transactionId = _extractTransactionId(invoice.notes!);
        if (transactionId == null) continue;

        try {
          // Get the actual transaction from transaction service
          final transactionService = Get.find<TransactionService>();
          final transaction = await transactionService.getTransactionById(transactionId);

          if (transaction == null || transaction.paymentStatus == 'paid') continue;

          final remainingDebt = transaction.totalAmount - transaction.amountPaid;

          if (remainingDebt <= 0) continue;

          // Calculate how much to pay for this transaction
          final paymentForThisTransaction = remainingPayment >= remainingDebt
              ? remainingDebt
              : remainingPayment;

          final newAmountPaid = transaction.amountPaid + paymentForThisTransaction;
          final newStatus = newAmountPaid >= transaction.totalAmount ? 'paid' : 'pending';
          final newChangeAmount = newStatus == 'paid'
              ? newAmountPaid - transaction.totalAmount
              : 0.0;

          // Update the transaction
          await transactionService.updateTransactionPayment(
            transactionId: transactionId,
            paymentMethod: selectedPaymentMethod.value,
            amountPaid: newAmountPaid,
            changeAmount: newChangeAmount,
            paymentStatus: newStatus,
          );

          // Reduce remaining payment amount
          remainingPayment -= paymentForThisTransaction;

          // If transaction is now fully paid, we can remove the customer invoice
          if (newStatus == 'paid') {
            // Update customer invoice amount to 0 or remove it
            // This depends on your business logic
          }

        } catch (e) {
          print('Error updating transaction $transactionId: $e');
          // Continue with other transactions even if one fails
        }
      }

      // Refresh history controller if it exists
      try {
        final historyController = Get.find<HistoryController>();
        await historyController.fetchTransactions();
      } catch (e) {
        print('History controller not found or error refreshing: $e');
      }

    } catch (e) {
      print('Error updating related transactions: $e');
      // Don't throw error as the payment was already successful
    }
  }

  String? _extractTransactionId(String notes) {
    try {
      // Expected format: "Transaksi: TRX-XXXXX"
      final regex = RegExp(r'Transaksi:\s*([A-Za-z0-9\-]+)');
      final match = regex.firstMatch(notes);
      return match?.group(1);
    } catch (e) {
      return null;
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
      await _refreshAllRelatedData();
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
                      GetBuilder<CustomerController>(
                        builder: (controller) {
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
                        },
                      ),
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
                      child: GetBuilder<CustomerController>(
                        builder: (controller) {
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
                        },
                      ),
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

  Future<void> _refreshAllRelatedData() async {
    // Refresh customer data
    await fetchCustomers();

    // Refresh selected customer transactions if any
    if (selectedCustomer.value != null) {
      await fetchCustomerTransactions(selectedCustomer.value!.id);
    }

    // Refresh history transactions
    try {
      final historyController = Get.find<HistoryController>();
      await historyController.fetchTransactions();
    } catch (e) {
      print('HistoryController not found, attempting to initialize: $e');
      try {
        Get.put(HistoryController());
        final historyController = Get.find<HistoryController>();
        await historyController.fetchTransactions();
      } catch (e2) {
        print('Could not initialize HistoryController: $e2');
      }
    }

    // Refresh transaction controller if exists
    try {
      final transactionController = Get.find<TransactionController>();
      await transactionController.loadCustomers();
    } catch (e) {
      print('TransactionController not found: $e');
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
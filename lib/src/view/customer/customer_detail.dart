// lib/src/view/customer/customer_detail_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import '../../controllers/customer_controller.dart';
import '../../models/customer_model.dart';

class CustomerDetailView extends StatelessWidget {
  final Customer customer;
  final CustomerController controller = Get.find<CustomerController>();

  CustomerDetailView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Load customer details when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectCustomer(customer);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
                onTap: () => controller.showCustomerForm(customer: customer),
              ),
              if (customer.hasBalance)
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.payment, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Terima Pembayaran', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  onTap: () => controller.showPaymentForm(customer),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Info Header
          Obx(() => _buildCustomerHeader(controller.selectedCustomer.value ?? customer)),

          // Tab Navigation
          Container(
            color: Colors.grey[100],
            child: Obx(() => Row(
              children: [
                Expanded(
                  child: _buildTabButton('Riwayat', 0),
                ),
                Expanded(
                  child: _buildTabButton('Transaksi', 1),
                ),
              ],
            )),
          ),

          // Tab Content
          Expanded(
            child: Obx(() => _buildTabContent()),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final currentCustomer = controller.selectedCustomer.value ?? customer;
        return currentCustomer.hasBalance
            ? FloatingActionButton(
          onPressed: () => controller.showPaymentForm(currentCustomer),
          backgroundColor: Colors.green,
          child: const Icon(Icons.payment, color: Colors.white),
          tooltip: 'Terima Pembayaran',
        )
            : const SizedBox.shrink();
      }),
    );
  }

  Widget _buildCustomerHeader(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and Basic Info
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: customer.hasBalance ? Colors.red.shade100 : Colors.green.shade100,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: customer.hasBalance ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customer.phoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            customer.phoneNumber!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    if (customer.email != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.email!,
                              style: TextStyle(color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: customer.hasBalance ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: customer.hasBalance ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Saldo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.formatCurrency(customer.balance),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: customer.hasBalance ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.hasBalance ? 'Belum Lunas' : 'Lunas',
                  style: TextStyle(
                    fontSize: 12,
                    color: customer.hasBalance ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Additional Info (if available)
          if (customer.address != null || customer.barcode != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (customer.address != null) ...[
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (customer.barcode != null) ...[
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        customer.barcode!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = controller.selectedTabIndex.value == index;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.setTabIndex(index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return RefreshIndicator(
      onRefresh: () => controller.fetchCustomerTransactions(customer.id),
      child: _buildTransactionList(),
    );
  }

  Widget _buildTransactionList() {
    final transactions = controller.filteredTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.selectedTabIndex.value == 0
                  ? Icons.history
                  : Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              controller.selectedTabIndex.value == 0
                  ? 'Belum ada riwayat transaksi'
                  : 'Belum ada transaksi aktif',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(CustomerTransaction transaction) {
    final isInvoice = transaction.isInvoice;
    final isPayment = transaction.isPayment;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Transaction Type & ID
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInvoice
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isInvoice ? 'PENJUALAN' : 'PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isInvoice
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.id,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                // Amount
                Text(
                  '${isInvoice ? '+' : '-'}${controller.formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isInvoice ? Colors.blue.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date & Payment Method
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  controller.formatDate(transaction.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (isPayment && transaction.paymentMethod != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    controller.getPaymentMethodDisplay(transaction.paymentMethod!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),

            // Status
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.isPaid
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: transaction.isPaid
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    transaction.isPaid ? 'LUNAS' : 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: transaction.isPaid
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),

            // Notes (if any)
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Catatan: ${transaction.notes!}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
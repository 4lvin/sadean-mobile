// lib/src/view/customer/customer_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import '../../controllers/customer_controller.dart';
import '../../models/customer_model.dart';
import 'customer_detail.dart';

class CustomerView extends StatelessWidget {
  final CustomerController controller = Get.put(CustomerController());

  CustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.fetchCustomers(),
          )),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              onChanged: (value) => controller.setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Cari nama, telepon, atau email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => controller.clearSearch(),
                ) : SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),

          // Customer List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.customers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredCustomers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.searchQuery.value.isNotEmpty
                            ? Icons.search_off
                            : Icons.people_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'Tidak ada pelanggan ditemukan'
                            : 'Belum ada pelanggan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (controller.searchQuery.value.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => controller.clearSearch(),
                          child: const Text('Hapus Filter'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchCustomers(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = controller.filteredCustomers[index];
                    return _buildCustomerCard(customer);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showCustomerForm(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Pelanggan',
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => CustomerDetailView(customer: customer)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: customer.hasBalance ? Colors.red.shade100 : Colors.green.shade100,
                child: Icon(
                  Icons.person,
                  color: customer.hasBalance ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),

              const SizedBox(width: 16),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer.phoneNumber != null) ...[
                      Text(
                        customer.phoneNumber!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (customer.email != null) ...[
                      Text(
                        customer.email!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Balance & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Balance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.hasBalance ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: customer.hasBalance ? Colors.red.shade300 : Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      controller.formatCurrency(customer.balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: customer.hasBalance ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Payment Button (only if has balance)
                      if (customer.hasBalance)
                        IconButton(
                          onPressed: () => controller.showPaymentForm(customer,),
                          icon: Icon(Icons.payment, color: Colors.green.shade600),
                          iconSize: 20,
                          tooltip: 'Terima Pembayaran',
                        ),

                      // Menu Button
                      PopupMenuButton(
                        iconSize: 20,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.visibility, size: 20),
                                SizedBox(width: 8),
                                Text('Detail'),
                              ],
                            ),
                            onTap: () => Get.to(() => CustomerDetailView(customer: customer)),
                          ),
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
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                            onTap: () => _confirmDeleteCustomer(customer),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCustomer(Customer customer) {
    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus pelanggan "${customer.name}"?\n\nData ini tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteCustomer(customer.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
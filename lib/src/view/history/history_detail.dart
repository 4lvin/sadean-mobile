// ===========================
// TRANSACTION DETAIL VIEW WITH PAYMENT TAB
// ===========================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import 'package:sadean/src/controllers/transaction_controller.dart';
import 'package:sadean/src/models/transaction_model.dart';

class TransactionDetailView extends StatelessWidget {
  final TransactionController controller = Get.find<TransactionController>();

  TransactionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with back button
          Container(
            color: primaryColor.withOpacity(0.8),
            padding: const EdgeInsets.only(top: 40, bottom: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rincian Transaksi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.receipt_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation tabs
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 50,
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTab('PRODUK', Icons.inventory_2_outlined, 0),
                        _buildTab('RINCIAN', Icons.receipt_long, 1),
                        _buildTab('PEMBAYARAN', Icons.payment, 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: Obx(() => _buildTabContent())),
        ],
      ),
      bottomNavigationBar: Obx(() => _buildBottomBar()),
    );
  }

  Widget _buildTab(String title, IconData icon, int index) {
    final isActive = controller.selectedTabIndex.value == index;
    final backgroundColor =
        isActive ? Colors.white : Colors.white.withOpacity(0.2);
    final textColor = isActive ? primaryColor : Colors.white;
    final iconColor = isActive ? primaryColor : Colors.white;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => controller.setSelectedTab(index),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTabIndex.value) {
      case 0:
        return _buildProductTab();
      case 1:
        return _buildDetailsTab();
      case 2:
        return _buildPaymentTab();
      default:
        return _buildProductTab();
    }
  }

  Widget _buildProductTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cart Items
        if (controller.cartItems.isNotEmpty)
          ...controller.cartItems.map((item) => _buildOrderItem(item)),

        if (controller.cartItems.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada produk di keranjang',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Order summary card
        Container(
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Rp ${controller.formatPrice(controller.cartSubtotal.value)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),

              // Discount
              if (controller.discount.value > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diskon ${_getDiscountLabel()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '-Rp ${controller.formatPrice(_calculateDiscountAmount())}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],

              // Service Fee
              if (controller.serviceFee.value > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biaya Layanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Rp ${controller.formatPrice(controller.serviceFee.value)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],

              // Shipping Cost
              if (controller.shippingCost.value > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biaya Pengiriman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Rp ${controller.formatPrice(controller.shippingCost.value)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],

              // Tax
              if (controller.tax.value > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pajak ${_getTaxLabel()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Rp ${controller.formatPrice(_calculateTaxAmount())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Profit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Laba',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Rp ${controller.formatPrice(controller.cartProfit.value)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Akhir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Rp ${controller.formatPrice(controller.cartTotal.value)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Order Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOrderOption(
                    Icons.local_shipping_outlined,
                    'Pengiriman',
                    onTap: () => _showShippingDialog(),
                    hasValue: controller.shippingCost.value > 0,
                  ),
                  _buildOrderOption(
                    Icons.local_offer_outlined,
                    'Diskon',
                    onTap: () => _showDiscountDialog(),
                    hasValue: controller.discount.value > 0,
                  ),
                  _buildOrderOption(
                    Icons.volunteer_activism_outlined,
                    'Layanan',
                    onTap: () => _showServiceDialog(),
                    hasValue: controller.serviceFee.value > 0,
                  ),
                  _buildOrderOption(
                    Icons.account_balance_outlined,
                    'Pajak',
                    onTap: () => _showTaxDialog(),
                    hasValue: controller.tax.value > 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Payment Summary Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final isPaid =
                    controller.amountPaid.value >= controller.cartTotal.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPaid ? 'AKAN LUNAS' : 'BELUM LUNAS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Total Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Akhir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Obx(
                    () => Text(
                      'Rp ${controller.formatPrice(controller.cartTotal.value)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Payment Status
              Obx(
                    () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.amountPaid.value >= controller.cartTotal.value
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.amountPaid.value >= controller.cartTotal.value
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.amountPaid.value >= controller.cartTotal.value
                            ? Icons.check_circle
                            : Icons.warning,
                        color: controller.amountPaid.value >= controller.cartTotal.value
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.amountPaid.value >= controller.cartTotal.value
                                  ? 'Siap untuk diproses'
                                  : controller.amountPaid.value > 0
                                  ? 'Pembayaran kurang'
                                  : 'Belum ada pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: controller.amountPaid.value >= controller.cartTotal.value
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                            if (controller.amountPaid.value < controller.cartTotal.value)
                              Text(
                                'Kurang: Rp ${controller.formatPrice(controller.cartTotal.value - controller.amountPaid.value)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Amount Paid
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kembali'),
                    Text(
                      'Rp ${controller.formatPrice(controller.changeAmount.value)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Pelanggan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(
            () => ListTile(
              leading: Icon(
                controller.selectedCustomer.value != null
                    ? Icons.person
                    : Icons.person_outline,
                color:
                    controller.selectedCustomer.value != null
                        ? Colors.blue
                        : Colors.grey,
              ),
              title: Text(
                controller.selectedCustomer.value?.name ?? 'Pilih Pelanggan',
                style: TextStyle(
                  color:
                      controller.selectedCustomer.value != null
                          ? Colors.black
                          : Colors.grey[600],
                ),
              ),
              subtitle:
                  controller.selectedCustomer.value != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.selectedCustomer.value!.phoneNumber !=
                              null)
                            Text(
                              controller.selectedCustomer.value!.phoneNumber!,
                            ),
                          Text(
                            'Saldo: ${controller.formatPrice(controller.selectedCustomer.value!.balance)}',
                            style: TextStyle(
                              color:
                                  controller.selectedCustomer.value!.hasBalance
                                      ? Colors.red
                                      : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                      : const Text('Transaksi tanpa pelanggan'),
              trailing: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              onTap: () {
                controller.loadCustomers();
                controller.showCustomerDialog();
              },
            ),
          ),
        ),
        // Payment Method Selection
        const Text(
          'Jenis Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(
            () => DropdownButtonFormField<String>(
              value: controller.paymentMethod.value,
              decoration: const InputDecoration(
                labelText: 'Pilih Metode Pembayaran',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Row(
                    children: [
                      Icon(Icons.payments, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Cash'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'qris',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('QRIS'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'transfer',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.purple),
                      SizedBox(width: 12),
                      Text('Transfer Bank'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.setPaymentMethod(value);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Payment Amount Input
        const Text(
          'Total Dibayar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller.totalAmount,
            decoration: const InputDecoration(
              labelText: 'Masukkan nominal',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              controller.setAmountPaid(amount);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Quick Payment Buttons
        const Text(
          'Total Dibayar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickPaymentButton('0%', 0),
            const SizedBox(width: 8),
            _buildQuickPaymentButton('50%', 0.5),
            const SizedBox(width: 8),
            _buildQuickPaymentButton('100%', 1.0),
          ],
        ),

        const SizedBox(height: 24),

        // Customer Information (Optional)
        const Text(
          'Informasi Tambahan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // // Only show customer name field if no customer is selected
        // Obx(() => controller.selectedCustomer.value == null
        //     ? Column(
        //   children: [
        //     Container(
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(12),
        //         border: Border.all(color: Colors.grey.shade300),
        //       ),
        //       child: TextField(
        //         decoration: const InputDecoration(
        //           labelText: 'Nama Pelanggan (Opsional)',
        //           border: InputBorder.none,
        //           contentPadding: EdgeInsets.symmetric(
        //               horizontal: 16, vertical: 12),
        //         ),
        //         onChanged: (value) {
        //           controller.customerName.value = value;
        //         },
        //       ),
        //     ),
        //     const SizedBox(height: 12),
        //   ],
        // )
        //     : const SizedBox.shrink()),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Catatan Transaksi',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
            onChanged: (value) {
              controller.transactionNotes.value = value;
            },
          ),
        ),
        const SizedBox(height: 8),
        // Payment Status Card
        Obx(
          () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  controller.canProcessPayment
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    controller.canProcessPayment
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  controller.canProcessPayment
                      ? Icons.check_circle
                      : Icons.warning,
                  color:
                      controller.canProcessPayment
                          ? Colors.green
                          : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.canProcessPayment
                            ? 'Siap untuk diproses'
                            : 'Pembayaran kurang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              controller.canProcessPayment
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                        ),
                      ),
                      if (!controller.canProcessPayment)
                        Text(
                          'Kurang: Rp ${controller.formatPrice(controller.cartTotal.value - controller.amountPaid.value)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPaymentButton(String label, double multiplier) {
    return Obx(() {
      final quickAmount = multiplier > 0
          ? (controller.cartTotal.value * multiplier).ceilToDouble()
          : 0.0; // Untuk 0%
      final isSelected = (controller.amountPaid.value - quickAmount).abs() < 0.01;

      return Container(
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              controller.setQuickPayment(multiplier);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOrderItem(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} x Rp ${controller.formatPrice(item.unitPrice)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              'Rp ${controller.formatPrice(item.quantity * item.unitPrice)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderOption(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool hasValue = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: hasValue ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: hasValue ? Border.all(color: primaryColor, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap:
                      onTap ??
                      () {
                        Get.snackbar('Info', '$label belum tersedia');
                      },
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Icon(
                      icon,
                      color: hasValue ? primaryColor : Colors.grey[600],
                      size: 26,
                    ),
                  ),
                ),
              ),
              if (hasValue)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: hasValue ? primaryColor : Colors.grey[700],
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (controller.selectedTabIndex.value == 2) {
      // Payment tab - show payment button
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(
            () => ElevatedButton(
              onPressed:
                  controller.isProcessingTransaction.value
                      ? null
                      : controller.canProcessPayment
                      ? () => controller.processTransaction()
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.canProcessPayment ? primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  controller.isProcessingTransaction.value
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('MEMPROSES...'),
                        ],
                      )
                      : const Text(
                        'BAYAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
            ),
          ),
        ),
      );
    } else {
      // Other tabs - show continue button
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(
            () => ElevatedButton(
              onPressed:
                  controller.cartItems.isEmpty
                      ? null
                      : () {
                        if (controller.selectedTabIndex.value < 2) {
                          controller.setSelectedTab(
                            controller.selectedTabIndex.value + 1,
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                controller.selectedTabIndex.value == 0
                    ? 'LANJUT KE RINCIAN'
                    : 'LANJUT KE PEMBAYARAN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // ===========================
  // HELPER METHODS
  // ===========================
  String _getDiscountLabel() {
    return controller.discountType.value == 'percentage'
        ? '(${controller.discount.value}%)'
        : '';
  }

  String _getTaxLabel() {
    return controller.taxType.value == 'percentage'
        ? '(${controller.tax.value}%)'
        : '';
  }

  double _calculateDiscountAmount() {
    return controller.discountType.value == 'percentage'
        ? controller.cartSubtotal.value * (controller.discount.value / 100)
        : controller.discount.value;
  }

  double _calculateTaxAmount() {
    final taxableAmount =
        controller.cartSubtotal.value -
        _calculateDiscountAmount() +
        controller.serviceFee.value +
        controller.shippingCost.value;

    return controller.taxType.value == 'percentage'
        ? taxableAmount * (controller.tax.value / 100)
        : controller.tax.value;
  }

  // ===========================
  // ADJUSTMENT DIALOGS
  // ===========================
  void _showShippingDialog() {
    final shippingController = TextEditingController(
      text:
          controller.shippingCost.value > 0
              ? controller.shippingCost.value.toString()
              : '',
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: primaryColor),
            const SizedBox(width: 12),
            const Text('Biaya Pengiriman'),
          ],
        ),
        content: TextField(
          controller: shippingController,
          decoration: const InputDecoration(
            labelText: 'Biaya Pengiriman',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              controller.shippingCost.value =
                  double.tryParse(shippingController.text) ?? 0;
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    final discountController = TextEditingController(
      text:
          controller.discount.value > 0
              ? controller.discount.value.toString()
              : '',
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_offer, color: primaryColor),
            const SizedBox(width: 12),
            const Text('Diskon'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: discountController,
              decoration: InputDecoration(
                labelText: 'Nilai Diskon',
                border: const OutlineInputBorder(),
                prefixText:
                    controller.discountType.value == 'percentage' ? '' : 'Rp ',
                suffixText:
                    controller.discountType.value == 'percentage' ? '%' : '',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.discountType.value,
                decoration: const InputDecoration(
                  labelText: 'Tipe Diskon',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'amount', child: Text('Rupiah')),
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Persentase'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.discountType.value = value;
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              controller.discount.value =
                  double.tryParse(discountController.text) ?? 0;
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showServiceDialog() {
    final serviceController = TextEditingController(
      text:
          controller.serviceFee.value > 0
              ? controller.serviceFee.value.toString()
              : '',
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.volunteer_activism, color: primaryColor),
            const SizedBox(width: 12),
            const Text('Biaya Layanan'),
          ],
        ),
        content: TextField(
          controller: serviceController,
          decoration: const InputDecoration(
            labelText: 'Biaya Layanan',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              controller.serviceFee.value =
                  double.tryParse(serviceController.text) ?? 0;
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog() {
    final taxController = TextEditingController(
      text: controller.tax.value > 0 ? controller.tax.value.toString() : '',
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.account_balance, color: primaryColor),
            const SizedBox(width: 12),
            const Text('Pajak'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taxController,
              decoration: InputDecoration(
                labelText: 'Nilai Pajak',
                border: const OutlineInputBorder(),
                prefixText:
                    controller.taxType.value == 'percentage' ? '' : 'Rp ',
                suffixText: controller.taxType.value == 'percentage' ? '%' : '',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.taxType.value,
                decoration: const InputDecoration(
                  labelText: 'Tipe Pajak',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'amount', child: Text('Rupiah')),
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Persentase'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.taxType.value = value;
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              controller.tax.value = double.tryParse(taxController.text) ?? 0;
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ===========================
// TRANSACTION DETAIL VIEW - ORIGINAL DESIGN WITH ADJUSTMENTS
// ===========================
import 'package:flutter/material.dart';
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTab('PRODUK', Icons.inventory_2_outlined, true),
                      _buildTab('RINCIAN', Icons.receipt_long, false),
                      _buildTab('PEMBAYARAN', Icons.payment, false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(
              () => ListView(
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
                        // Cart Items
                        ...controller.cartItems.map(
                          (item) => _buildOrderItem(item),
                        ),

                        if (controller.cartItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(thickness: 1),
                          const SizedBox(height: 16),
                        ],

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

                        // Discount (if any)
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

                        // Service Fee (if any)
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

                        // Shipping Cost (if any)
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

                        // Tax (if any)
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order options - Enhanced with adjustments
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
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
                      : () => controller.processTransaction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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
                        'BAYAR LUNAS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    );
  }

  Widget _buildTab(String title, IconData icon, bool isActive) {
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
            onTap: () {},
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
    final controller = Get.find<TransactionController>();
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
    final controller = Get.find<TransactionController>();
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
    final controller = Get.find<TransactionController>();
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
    final controller = Get.find<TransactionController>();
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

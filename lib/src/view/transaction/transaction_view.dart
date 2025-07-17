import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/assets.dart';
import 'package:sadean/src/config/theme.dart';
import 'package:sadean/src/routers/constant.dart';
import 'package:sadean/src/service/product_service.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../service/secure_storage_service.dart';
import '../history/history_detail.dart';

class TransactionView extends StatelessWidget {
  final TransactionController controller = Get.find<TransactionController>();

  TransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Tambah Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _confirmExit(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () => controller.scanBarcode(),
          ),
        ],
        elevation: 0,
      ),
      body: Obx(
        () => Stack(
          children: [
            Column(
              children: [
                // Search Bar & Category Filter
                Container(
                  color: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        controller: controller.searchController,
                        onChanged: (value) => controller.setSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Nama / SKU / Barcode',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              controller.searchQuery.value.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      controller.searchController.clear();
                                      controller.setSearchQuery('');
                                    },
                                  )
                                  : const Icon(Icons.edit),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category Filter Chips
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            FilterChip(
                              label: const Text('Semua'),
                              selected:
                                  controller.selectedCategoryId.value.isEmpty,
                              onSelected:
                                  (_) => controller.setSelectedCategory(''),
                              backgroundColor: Colors.white.withOpacity(0.8),
                              selectedColor: secondaryColor,
                            ),
                            const SizedBox(width: 8),
                            ...controller.categories
                                .map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category.name),
                                      selected:
                                          controller.selectedCategoryId.value ==
                                          category.id,
                                      onSelected:
                                          (_) => controller.setSelectedCategory(
                                            category.id,
                                          ),
                                      backgroundColor: Colors.white.withOpacity(
                                        0.8,
                                      ),
                                      selectedColor: secondaryColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Product List
                Obx(
                  () => Expanded(
                    child:
                        controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : controller.filteredProducts.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                              onRefresh: () => controller.loadInitialData(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: controller.filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product =
                                      controller.filteredProducts[index];
                                  return _buildProductCard(product);
                                },
                              ),
                            ),
                  ),
                ),
              ],
            ),

            // Cart Bottom Sheet
            if (controller.showCart.value)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildCartBottomSheet(),
              ),
          ],
        ),
      ),

      // Bottom Navigation with Cart Summary
      bottomNavigationBar: Obx(
        () =>
            controller.cartItems.isNotEmpty
                ? _buildCartSummaryBar()
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final storage = Get.find<ProductService>();

    return Obx(
      () => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => controller.quickAddProduct(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        product.imageUrl != null
                            ? Image.file(
                              File(product.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                            )
                            : Icon(Icons.image, color: Colors.grey[400]),
                  ),
                ),

                const SizedBox(width: 12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(product.categoryId),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Rp ${controller.formatPrice(product.sellingPrice)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${product.stock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  product.stock <= product.minStock
                                      ? Colors.red
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Add Button / Quantity Controls
                Column(
                  children: [
                    if (controller.getCartQuantity(product.id) > 0) ...[
                      // Quantity Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.getCartQuantity(product.id)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quantity Controls Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Decrease Button
                          Material(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap:
                                  () => controller.updateCartItemQuantity(
                                    product.id,
                                    controller.getCartQuantity(product.id) - 1,
                                  ),
                              child: Container(
                                width: 28,
                                height: 28,
                                child: const Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Increase Button
                          Material(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap:
                                  product.stock >
                                          controller.getCartQuantity(product.id)
                                      ? () => controller.addToCart(product)
                                      : null,
                              child: Container(
                                width: 28,
                                height: 28,
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Add Button for new items
                      Material(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap:
                              product.stock > 0
                                  ? () => controller.addToCart(product)
                                  : null,
                          child: Container(
                            width: 60,
                            height: 36,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Tidak ada produk ditemukan'
                : 'Belum ada produk',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (controller.searchQuery.value.isNotEmpty)
            TextButton(
              onPressed: () => controller.clearFilters(),
              child: const Text('Hapus Filter'),
            ),
        ],
      ),
    );
  }

  Widget _buildCartBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Scrollable Area (handle, header, list)
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Handle
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(
                              () => Text(
                                "KERANJANG (${controller.cartItemCount.value})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Adjustment Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.tune,
                                    color: Colors.blue,
                                  ),
                                  onPressed:
                                      () => controller.showAdjustmentsDialog(),
                                  tooltip: 'Pengaturan Transaksi',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.save),
                                  onPressed: () => controller.saveCart(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _confirmClearCart(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cart Items
                    Obx(
                      () => SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = controller.cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildCartItem(item),
                          );
                        }, childCount: controller.cartItems.length),
                      ),
                    ),

                    // Add some space before total summary
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),

              // Enhanced Total Summary (Fixed at bottom)
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Detailed breakdown
                      _buildSummaryRow(
                        'Subtotal',
                        controller.cartSubtotal.value,
                      ),

                      // Show adjustments if any
                      if (controller.discount.value > 0)
                        _buildSummaryRow(
                          'Diskon ${controller.discountType.value == 'percentage' ? '(${controller.discount.value}%)' : ''}',
                          controller.discountType.value == 'percentage'
                              ? -(controller.cartSubtotal.value *
                                  (controller.discount.value / 100))
                              : -controller.discount.value,
                          isNegative: true,
                        ),

                      if (controller.serviceFee.value > 0)
                        _buildSummaryRow(
                          'Biaya Layanan',
                          controller.serviceFee.value,
                        ),

                      if (controller.shippingCost.value > 0)
                        _buildSummaryRow(
                          'Biaya Pengiriman',
                          controller.shippingCost.value,
                        ),

                      if (controller.tax.value > 0)
                        _buildSummaryRow(
                          'Pajak ${controller.taxType.value == 'percentage' ? '(${controller.tax.value}%)' : ''}',
                          controller.taxType.value == 'percentage'
                              ? (controller.cartSubtotal.value -
                                      (controller.discountType.value ==
                                              'percentage'
                                          ? controller.cartSubtotal.value *
                                              (controller.discount.value / 100)
                                          : controller.discount.value) +
                                      controller.serviceFee.value +
                                      controller.shippingCost.value) *
                                  (controller.tax.value / 100)
                              : controller.tax.value,
                        ),

                      // Show divider if there are adjustments
                      if (controller.discount.value > 0 ||
                          controller.serviceFee.value > 0 ||
                          controller.shippingCost.value > 0 ||
                          controller.tax.value > 0)
                        const Divider(thickness: 1),

                      // Final total
                      _buildSummaryRow(
                        'Total',
                        controller.cartTotal.value,
                        isBold: true,
                        fontSize: 18,
                      ),

                      const SizedBox(height: 8),

                      // Profit information
                      _buildSummaryRow(
                        'Estimasi Laba',
                        controller.cartProfit.value,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color ?? (isBold ? Colors.black : Colors.grey.shade700),
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}Rp ${controller.formatPrice(amount.abs())}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color:
                  isNegative
                      ? Colors.red
                      : (color ??
                          (isBold ? Colors.black : Colors.grey.shade700)),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Cart Summary Bar
  Widget _buildCartSummaryBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Adjustments Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(50),
            ),
            child: InkWell(
              onTap: () => controller.showAdjustmentsDialog(),
              child: const Icon(Icons.tune, color: Colors.blue),
            ),
          ),

          const SizedBox(width: 8),

          // Save Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(50),
            ),
            child: InkWell(
              onTap: () => controller.saveCart(),
              child: const Icon(Icons.save),
            ),
          ),

          const SizedBox(width: 12),

          // Total & Process Button
          Expanded(
            child: Obx(
              () => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed:
                    controller.isProcessingTransaction.value
                        ? null
                        : () => Get.to(() => TransactionDetailView()),
                child:
                    controller.isProcessingTransaction.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp ${controller.formatPrice(controller.cartTotal.value)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // Show if there are adjustments
                            if (controller.discount.value > 0 ||
                                controller.serviceFee.value > 0 ||
                                controller.shippingCost.value > 0 ||
                                controller.tax.value > 0)
                              Text(
                                'Subtotal: Rp ${controller.formatPrice(controller.cartSubtotal.value)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(TransactionItem item) {
    final product = controller.products.firstWhere(
      (p) => p.id == item.productId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${controller.formatPrice(item.unitPrice)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                    onTap:
                        () => controller.updateCartItemQuantity(
                          item.productId,
                          item.quantity - 1,
                        ),
                    child: Container(
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

                // Quantity Display
                Container(
                  width: 40,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Increase Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                    onTap:
                        product.stock > item.quantity
                            ? () => controller.updateCartItemQuantity(
                              item.productId,
                              item.quantity + 1,
                            )
                            : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color:
                            product.stock > item.quantity
                                ? Colors.green
                                : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Item Total & Remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${controller.formatPrice(item.quantity * item.unitPrice)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _confirmRemoveItem(item),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemoveItem(TransactionItem item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Hapus ${item.productName} dari keranjang?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeFromCart(item.productId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    try {
      return controller.categories
          .firstWhere((cat) => cat.id == categoryId)
          .name;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _confirmExit() {
    if (controller.cartItems.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text(
            'Ada item di keranjang. Simpan atau hapus keranjang?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                controller.saveCart();
                Get.back();
              },
              child: const Text('Simpan'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                controller.clearCart();
                Get.back();
              },
              child: const Text('Hapus'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  void _confirmClearCart() {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Keranjang?'),
        content: const Text('Semua item akan dihapus dari keranjang.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearCart();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

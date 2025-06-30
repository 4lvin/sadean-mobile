import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/view/product/edit_produk_view.dart';
import '../../config/theme.dart';
import '../../controllers/product_controller.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

class ProductDetailView extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();
  final Product product;

  ProductDetailView({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editProduct(),
            tooltip: 'Edit Produk',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _confirmDelete(),
            tooltip: 'Hapus Produk',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product.imageUrl != null
                      ? Hero(
                    tag: 'product-hero-${product.id}',
                    child: Image.file(
                      File(product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey[400]
                      ),
                    ),
                  )
                      : Icon(
                    Icons.image,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Product Name Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            controller.categories
                                .firstWhere((cat) => cat.id == product.categoryId,
                                orElse: () => Category(id: '', name: 'Unknown'))
                                .name,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildStockStatusBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stock Status Alert (if needed)
            if (product.isStockEnabled && product.stock <= product.minStock)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: product.stock == 0 ? Colors.red.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: product.stock == 0 ? Colors.red.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      product.stock == 0 ? Icons.error : Icons.warning,
                      color: product.stock == 0 ? Colors.red.shade700 : Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.stock == 0
                            ? 'Produk habis! Segera lakukan restok.'
                            : 'Stok rendah! Segera lakukan restok.',
                        style: TextStyle(
                          color: product.stock == 0 ? Colors.red.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Product Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Produk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('SKU', product.sku, Icons.qr_code),
                    _buildDetailRow('Barcode', product.barcode, Icons.qr_code_scanner),
                    _buildDetailRow('Satuan', product.unit, Icons.straighten),
                    const Divider(height: 32),
                    _buildDetailRow(
                      'Harga Modal',
                      'Rp ${_formatPrice(product.costPrice)}',
                      Icons.money,
                      valueColor: Colors.orange.shade700,
                    ),
                    _buildDetailRow(
                      'Harga Jual',
                      'Rp ${_formatPrice(product.sellingPrice)}',
                      Icons.attach_money,
                      valueColor: Colors.green.shade700,
                    ),
                    _buildDetailRow(
                      'Laba per Unit',
                      'Rp ${_formatPrice(product.profitPerUnit)} (${product.profitMargin.toStringAsFixed(1)}%)',
                      Icons.trending_up,
                      valueColor: product.profitPerUnit > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const Divider(height: 32),
                    if (product.isStockEnabled) ...[
                      _buildDetailRow(
                        'Stok Saat Ini',
                        '${product.stock} ${product.unit}',
                        Icons.inventory,
                        valueColor: product.stock <= product.minStock ? Colors.red.shade700 : null,
                      ),
                      _buildDetailRow(
                        'Stok Minimum',
                        '${product.minStock} ${product.unit}',
                        Icons.warning_amber,
                      ),
                      _buildDetailRow(
                        'Nilai Stok',
                        'Rp ${_formatPrice(product.stock * product.costPrice)}',
                        Icons.calculate,
                        valueColor: Colors.blue.shade700,
                      ),
                    ] else
                      _buildDetailRow(
                        'Stok',
                        'Unlimited',
                        Icons.all_inclusive,
                        valueColor: Colors.blue.shade700,
                      ),
                    _buildDetailRow(
                      'Total Terjual',
                      '${product.soldCount} ${product.unit}',
                      Icons.shopping_cart,
                      valueColor: Colors.purple.shade700,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addToTransaction(),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Tambah ke Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editProduct(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Produk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatusBadge() {
    if (!product.isStockEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Text(
          'UNLIMITED',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (product.stock == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Text(
          'HABIS',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (product.stock <= product.minStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Text(
          'RENDAH',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Text(
        'TERSEDIA',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProduct() {
    Get.to(() => EditProductView(product: product));
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: 'Apakah Anda yakin ingin menghapus "${product.name}"?\n\nTindakan ini tidak dapat dibatalkan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.grey[600],
      onConfirm: () async {
        Get.back(); // Close dialog
        try {
          await controller.deleteProduct(product.id);
          Get.back(); // Go back to product list
        } catch (e) {
          // Error is already handled in controller
        }
      },
    );
  }

  void _addToTransaction() {
    // Check if product can be sold
    if (product.isStockEnabled && product.stock <= 0) {
      Get.snackbar(
        'Stok Habis',
        'Produk "${product.name}" sedang habis stok',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
      return;
    }

    // Navigate to transaction view dan tambahkan produk ke cart
    Get.toNamed('/transaction', arguments: {'addProduct': product});
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
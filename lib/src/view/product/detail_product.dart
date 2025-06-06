import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        title: const Text('Detail Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProduct(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(),
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.imageUrl != null
                      ? Hero(
                    tag: 'product-hero-${product.id}',
                    child: Image.file(
                      File(product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
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

            // Stock Status Badge
            if (product.stock <= product.minStock)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Stok Rendah! Segera lakukan restok.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Product Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 16),
                    _buildDetailRow('Nama Produk', product.name),
                    _buildDetailRow(
                        'Kategori',
                        controller.categories
                            .firstWhere((cat) => cat.id == product.categoryId,
                            orElse: () => Category(id: '', name: 'Unknown'))
                            .name
                    ),
                    _buildDetailRow('SKU', product.sku),
                    _buildDetailRow('Barcode', product.barcode),
                    _buildDetailRow('Harga Modal', 'Rp ${_formatPrice(product.costPrice)}'),
                    _buildDetailRow('Harga Jual', 'Rp ${_formatPrice(product.sellingPrice)}'),
                    _buildDetailRow('Satuan', product.unit),
                    _buildDetailRow('Stok', '${product.stock}'),
                    _buildDetailRow('Stok Minimum', '${product.minStock}'),
                    _buildDetailRow('Total Terjual', '${product.soldCount}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _editProduct(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editProduct() {
    // Pre-fill form dengan data produk
    controller.nameController.text = product.name;
    controller.selectedCategoryId.value = product.categoryId;
    controller.skuController.text = product.sku;
    controller.barcodeController.text = product.barcode;
    controller.costPriceController.text = product.costPrice.toString();
    controller.sellingPriceController.text = product.sellingPrice.toString();
    controller.unitController.text = product.unit;
    controller.stockController.text = product.stock.toString();
    controller.minStockController.text = product.minStock.toString();

    // Get.to(() => EditProductView(product: product));
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Apakah Anda yakin ingin menghapus ${product.name}?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await controller.deleteProduct(product.id);
      },
    );
  }

  void _addToTransaction() {
    // Navigate to transaction view dan tambahkan produk ke cart
    Get.toNamed('/transaction', arguments: {'addProduct': product});
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}

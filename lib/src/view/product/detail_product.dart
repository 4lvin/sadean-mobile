import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        title: Text('Detail Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit product screen
              // In a real app, you would prefill the form with product data
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
                  image: product.imageUrl != null
                      ? DecorationImage(
                    image: FileImage(File(product.imageUrl!)),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Icon(
                  Icons.image,
                  size: 80,
                  color: Colors.grey[400],
                )
                    : null,
              ),
            ),

            SizedBox(height: 24),

            // Product Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Add to transaction feature
                    },
                    icon: Icon(Icons.add_shopping_cart),
                    label: Text('Tambah ke Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    // Delete product with confirmation
                    Get.defaultDialog(
                      title: 'Konfirmasi Hapus',
                      middleText: 'Apakah Anda yakin ingin menghapus ${product.name}?',
                      textConfirm: 'Hapus',
                      textCancel: 'Batal',
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        // In a real app, delete from database
                        controller.products.removeWhere((p) => p.id == product.id);
                        Get.back();
                        Get.back();
                        Get.snackbar('Sukses', 'Produk berhasil dihapus');
                      },
                    );
                  },
                  icon: Icon(Icons.delete),
                  color: Colors.red,
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
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
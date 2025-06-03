import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import 'package:sadean/src/routers/constant.dart';
import 'package:sadean/src/view/product/category_management.dart';
import 'package:sadean/src/view/product/detail_product.dart';
import '../../controllers/product_controller.dart';
import '../../service/product_service.dart';
import '../../service/secure_storage_service.dart';

class ProductsView extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: Icon(Icons.category),
            onPressed: () => _showCategoryManagement(),
          ),
          Obx(() => IconButton(
            icon: Icon(controller.isGridView.value ? Icons.view_list : Icons.grid_view),
            tooltip: controller.isGridView.value ? 'Tampilkan sebagai List' : 'Tampilkan sebagai Grid',
            onPressed: () {
              controller.isGridView.value = !controller.isGridView.value;
            },
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada produk',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(productsAddRoute),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadData(),
          child: Obx(() {
            return controller.isGridView.value
                ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: controller.products.length,
              itemBuilder: (context, index) {
                final product = controller.products[index];
                return _buildProductCard(product, isGrid: true);
              },
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.products.length,
              itemBuilder: (context, index) {
                final product = controller.products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildProductCard(product, isGrid: false),
                );
              },
            );
          }),
        );
      }),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          heroTag: 'fab-product',
          onPressed: () => Get.toNamed(productsAddRoute),
          child: const Icon(Icons.add, color: secondaryColor),
          tooltip: 'Tambah Produk',
        ),
      ),
    );
  }

  Widget _buildProductCard(product, {bool isGrid = true}) {
    final storage = Get.find<ProductService>();
    final imageWidget = product.imageUrl != null
        ? Hero(
      tag: 'product-hero-${product.id}', // pastikan unik
      child: Image.memory(
        storage.base64ToImage(product.imageUrl)!,
        fit: BoxFit.cover,
      ),
    ) : Icon(Icons.image, size: 50, color: Colors.grey[400]);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: isGrid
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar atas
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildProductDetails(product),
            ),
          ],
        )
            : Row(
          children: [
            // Gambar kiri
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: imageWidget,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildProductDetails(product),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'Rp ${_formatPrice(product.sellingPrice)}',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stok: ${product.stock} ${product.unit}',
              style: TextStyle(
                fontSize: 12,
                color: product.stock <= product.minStock
                    ? Colors.red
                    : Colors.grey[600],
              ),
            ),
            if (product.stock <= product.minStock)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showProductDetail(product) {
    Get.to(() => ProductDetailView(product: product));
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cari Produk'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama, SKU, atau Barcode',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Get.back();
            _performSearch(query);
          },
        ),
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      controller.loadData();
      return;
    }

    final service = Get.find<ProductService>();
    final results = await service.searchProducts(query);
    controller.products.assignAll(results);
  }

  void _showCategoryManagement() {
    Get.to(() => CategoryManagementView());
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}

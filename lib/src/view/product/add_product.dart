import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';

class AddProductView extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        actions: [
          Obx(() => IconButton(
            icon: controller.isLoading.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save),
            onPressed: controller.isLoading.value ? null : () => controller.saveProduct(),
          )),
        ],
      ),
      body: Obx(() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Center(
              child: GestureDetector(
                onTap: controller.isLoading.value ? null : () => controller.selectImage(),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: controller.selectedImage.value != null
                        ? Image.file(
                      controller.selectedImage.value!,
                      fit: BoxFit.cover,
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Tambah Gambar',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Product Name
            TextFormField(
              controller: controller.nameController,
              enabled: !controller.isLoading.value,
              decoration: const InputDecoration(
                labelText: 'Nama Produk*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            Obx(()=>DropdownButtonFormField<String>(
              value: controller.selectedCategoryId.value,
              decoration: const InputDecoration(
                labelText: 'Kategori*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: controller.categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: controller.isLoading.value
                  ? null
                  : (value) {
                controller.selectedCategoryId.value = value;
              },
              hint: const Text('Pilih Kategori'),
            )),

            const SizedBox(height: 16),

            // SKU
            TextFormField(
              controller: controller.skuController,
              enabled: !controller.isLoading.value,
              decoration: const InputDecoration(
                labelText: 'SKU*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
                hintText: 'Kode unik produk',
              ),
            ),

            const SizedBox(height: 16),

            // Barcode with Scan button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.barcodeController,
                    enabled: !controller.isLoading.value,
                    decoration: const InputDecoration(
                      labelText: 'Barcode*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : () => controller.scanBarcode(),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 56),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price Group
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.costPriceController,
                    enabled: !controller.isLoading.value,
                    decoration: const InputDecoration(
                      labelText: 'Harga Modal*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.sellingPriceController,
                    enabled: !controller.isLoading.value,
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Unit
            TextFormField(
              controller: controller.unitController,
              enabled: !controller.isLoading.value,
              decoration: const InputDecoration(
                labelText: 'Satuan*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
                hintText: 'pcs, kg, box, dll',
              ),
            ),

            const SizedBox(height: 16),

            // Stock Group
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.stockController,
                    enabled: !controller.isLoading.value,
                    decoration: const InputDecoration(
                      labelText: 'Stok*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.minStockController,
                    enabled: !controller.isLoading.value,
                    decoration: const InputDecoration(
                      labelText: 'Stok Minimum*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.saveProduct(),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Simpan Produk',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
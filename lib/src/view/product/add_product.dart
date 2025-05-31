import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';

class AddProductView extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => controller.saveProduct(),
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
              child: Obx(() => GestureDetector(
                onTap: () => controller.selectImage(),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: controller.selectedImage.value != null
                        ? DecorationImage(
                      image: FileImage(controller.selectedImage.value!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: controller.selectedImage.value == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Tambah Gambar',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  )
                      : null,
                ),
              )),
            ),

            SizedBox(height: 24),

            // Product Name
            TextFormField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: 'Nama Produk*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
            ),

            SizedBox(height: 16),

            // Category Dropdown
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedCategoryId.value,
              decoration: InputDecoration(
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
              onChanged: (value) {
                controller.selectedCategoryId.value = value;
              },
              hint: Text('Pilih Kategori'),
            )),

            SizedBox(height: 16),

            // SKU
            TextFormField(
              controller: controller.skuController,
              decoration: InputDecoration(
                labelText: 'SKU*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),

            SizedBox(height: 16),

            // Barcode with Scan button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Barcode*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => controller.scanBarcode(),
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 56),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Price Group
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.costPriceController,
                    decoration: InputDecoration(
                      labelText: 'Harga Modal*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.sellingPriceController,
                    decoration: InputDecoration(
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

            SizedBox(height: 16),

            // Unit
            TextFormField(
              controller: controller.unitController,
              decoration: InputDecoration(
                labelText: 'Satuan*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
                hintText: 'pcs, kg, box, dll',
              ),
            ),

            SizedBox(height: 16),

            // Stock Group
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.stockController,
                    decoration: InputDecoration(
                      labelText: 'Stok*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.minStockController,
                    decoration: InputDecoration(
                      labelText: 'Stok Minimum*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => controller.saveProduct(),
                child: Text(
                  'Simpan Produk',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
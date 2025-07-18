import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import '../../config/theme.dart';
import '../../controllers/product_controller.dart';
import '../../service/category_service.dart';
import '../../service/currency_input_formatter.dart';

class AddProductView extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();

  AddProductView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => TextButton.icon(
            onPressed: controller.isLoading.value ? null : () => controller.saveProduct(),
            icon: controller.isLoading.value
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Simpan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )),
        ],
      ),
      body: Obx(() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            _buildImageSection(),

            const SizedBox(height: 24),

            // Basic Information Card
            _buildBasicInfoCard(),

            const SizedBox(height: 16),

            // Pricing Card
            _buildPricingCard(),

            const SizedBox(height: 16),

            // Stock Management Card
            _buildStockCard(),

            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(),

            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Foto Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: controller.isLoading.value ? null : () => controller.selectImage(),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Obx(() => controller.selectedImage.value != null
                        ? Stack(
                      children: [
                        Image.file(
                          controller.selectedImage.value!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                              onPressed: () => controller.selectImage(),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),

                        // Stock Value Indicator
                        Obx(() {
                          if (controller.stockValue.value > 0 && controller.costPrice.value > 0) {
                            final totalStockValue = controller.stockValue.value * controller.costPrice.value;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calculate, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Nilai Total Stok: Rp ${totalStockValue.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        Text(
                          'Tambah Foto Produk',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ketuk untuk memilih foto',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateSKU() {
    if (controller.selectedCategoryId.value == null || controller.selectedCategoryId.value!.isEmpty) {
      Get.snackbar(
        'Pilih Kategori',
        'Pilih kategori terlebih dahulu untuk generate SKU',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    final now = DateTime.now();
    final selectedCategory = controller.categories.firstWhere(
          (cat) => cat.id == controller.selectedCategoryId.value!,
    );

    // Take first 3 letters of category name (uppercase)
    final categoryCode = selectedCategory.name.length >= 3
        ? selectedCategory.name.substring(0, 3).toUpperCase()
        : selectedCategory.name.toUpperCase().padRight(3, 'X');

    // Use timestamp for uniqueness
    final timestamp = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final generatedSKU = '$categoryCode$timestamp';
    controller.skuController.text = generatedSKU;

    Get.snackbar(
      'SKU Generated',
      'SKU berhasil di-generate: $generatedSKU',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.auto_awesome, color: Colors.blue),
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Dasar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Product Name
            _buildTextField(
              controller: controller.nameController,
              label: 'Nama Produk *',
              icon: Icons.inventory_2,
              hint: 'Masukkan nama produk',
            ),

            const SizedBox(height: 8),

            // Category Dropdown with Add Button
            Row(
              children: [
                const Text(
                  'Kategori *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (controller.categories.isEmpty)
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Tambah Kategori',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<String>(
                value: (controller.selectedCategoryId.value == null ||
                    controller.selectedCategoryId.value!.isEmpty)
                    ? null
                    : controller.selectedCategoryId.value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.category),
                ),
                hint: Text(controller.categories.isEmpty
                    ? 'Belum ada kategori - Tambah kategori terlebih dahulu'
                    : 'Pilih Kategori'),
                isExpanded: true,
                items: controller.categories.isEmpty
                    ? null
                    : controller.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (controller.isLoading.value || controller.categories.isEmpty)
                    ? null
                    : (value) {
                  controller.selectedCategoryId.value = value ?? '';
                },
              ),
            )),

            const SizedBox(height: 8),

            // SKU and Barcode Row
            Row(
              children: [
                const Text(
                  'SKU (Opsional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _generateSKU(),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    'Generate',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: controller.skuController,
                enabled: !controller.isLoading.value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.qr_code),
                  hintText: 'Auto-generate jika kosong',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Barcode *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: controller.barcodeController,
                          enabled: !controller.isLoading.value,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(Icons.qr_code_scanner),
                            hintText: 'Scan atau ketik barcode',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: controller.isLoading.value ? null : () => _scanBarcode(),
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        tooltip: 'Scan Barcode',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Unit
            _buildTextField(
              controller: controller.unitController,
              label: 'Satuan *',
              icon: Icons.straighten,
              hint: 'pcs, kg, box, liter, dll',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Harga',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.costPriceController,
                    label: 'Harga Modal *',
                    icon: Icons.money,
                    hint: '0',
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: controller.sellingPriceController,
                    label: 'Harga Jual *',
                    icon: Icons.attach_money,
                    hint: '0',
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Profit Margin Indicator
            Obx(() {
              if (controller.costPrice.value > 0 && controller.sellingPrice.value > 0) {
                final profit = controller.calculatedProfitAmount;
                final margin = controller.calculatedProfitMargin;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: margin > 0 ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: margin > 0 ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        margin > 0 ? Icons.trending_up : Icons.trending_down,
                        color: margin > 0 ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Laba: Rp ${profit.toStringAsFixed(0)} (${margin.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: margin > 0 ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Manajemen Stok',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Obx(() => Switch(
                  value: controller.isStockEnabled.value,
                  onChanged: (value) => controller.toggleStockTracking(value),
                  activeColor: primaryColor,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              controller.isStockEnabled.value
                  ? 'Pelacakan stok diaktifkan - Stok akan dikurangi saat transaksi'
                  : 'Pelacakan stok dinonaktifkan - Stok tidak terbatas',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            )),

            Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: controller.isStockEnabled.value ? null : 0,
              child: controller.isStockEnabled.value
                  ? Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: controller.stockController,
                          label: 'Stok Awal *',
                          icon: Icons.inventory,
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: controller.minStockController,
                          label: 'Stok Minimum *',
                          icon: Icons.warning,
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stock Warning Indicator
                  Obx(() {
                    if (controller.stockValue.value > 0 &&
                        controller.minStockValue.value > 0 &&
                        controller.stockValue.value <= controller.minStockValue.value) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Peringatan: Stok awal (${controller.stockValue.value}) <= stok minimum (${controller.minStockValue.value})',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              )
                  : const SizedBox.shrink(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            enabled: !this.controller.isLoading.value,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(icon),
              prefixText: prefixText,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : () => controller.saveProduct(),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: controller.isLoading.value
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
            Text('Menyimpan...'),
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save),
            SizedBox(width: 8),
            Text(
              'Simpan Produk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // Color for scan line
        'Batal',   // Cancel button text
        true,      // Show flash icon
        ScanMode.BARCODE,
      );

      if (barcode != '-1' && barcode.isNotEmpty) {
        controller.barcodeController.text = barcode;
        Get.snackbar(
          'Berhasil',
          'Barcode berhasil dipindai: $barcode',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal scan barcode: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  void _showAddCategoryDialog() {
    final categoryController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Kategori Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Kategori akan langsung tersedia setelah ditambahkan.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (categoryController.text.trim().isNotEmpty) {
                try {
                  Get.back(); // Close dialog first

                  // Add category
                  final categoryService = Get.find<CategoryService>();
                  final newCategory = await categoryService.addCategory(categoryController.text.trim());

                  // Reload categories
                  await controller.loadData();

                  // Auto-select the new category
                  controller.selectedCategoryId.value = newCategory.id;

                  Get.snackbar(
                    'Berhasil',
                    'Kategori "${newCategory.name}" berhasil ditambahkan',
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.green.shade800,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Gagal menambah kategori: $e',
                    backgroundColor: Colors.red.shade100,
                    colorText: Colors.red.shade800,
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                }
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
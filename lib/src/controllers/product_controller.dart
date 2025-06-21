import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sadean/src/controllers/transaction_controller.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../service/category_service.dart';
import '../service/product_service.dart';

class ProductController extends GetxController {
  final ProductService _service = Get.find<ProductService>();
  final TransactionController _transactionController = Get.put(TransactionController());
  final CategoryService _categoryService = Get.find<CategoryService>();

  final RxList<Product> products = <Product>[].obs;
  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isGridView = true.obs;

  // Stock tracking toggle
  final RxBool isStockEnabled = true.obs;

  // Observable variables for real-time calculations
  final RxDouble costPrice = 0.0.obs;
  final RxDouble sellingPrice = 0.0.obs;
  final RxInt stockValue = 0.obs;
  final RxInt minStockValue = 0.obs;

  // Form controllers (keeping existing ones)
  final nameController = TextEditingController();
  final skuController = TextEditingController();
  final barcodeController = TextEditingController();
  final costPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final unitController = TextEditingController();
  final stockController = TextEditingController();
  final minStockController = TextEditingController();

  final Rx<String?> selectedCategoryId = Rx<String?>(null);
  final Rx<File?> selectedImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    loadData();
    _initializeStockControllers();
  }

  @override
  void onClose() {
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    unitController.dispose();
    stockController.dispose();
    minStockController.dispose();
    super.onClose();
  }

  void _initializeStockControllers() {
    // Set default values when stock tracking is enabled
    stockController.text = '0';
    minStockController.text = '0';

    // Add listeners to text controllers for real-time updates
    costPriceController.addListener(() {
      costPrice.value = double.tryParse(costPriceController.text) ?? 0.0;
    });

    sellingPriceController.addListener(() {
      sellingPrice.value = double.tryParse(sellingPriceController.text) ?? 0.0;
    });

    stockController.addListener(() {
      stockValue.value = int.tryParse(stockController.text) ?? 0;
    });

    minStockController.addListener(() {
      minStockValue.value = int.tryParse(minStockController.text) ?? 0;
    });

    // Listen to stock tracking changes
    ever(isStockEnabled, (enabled) {
      if (!enabled) {
        // When disabled, set stock to unlimited (-1 or high number)
        stockController.text = '999999';
        minStockController.text = '0';
      } else if (stockController.text == '999999') {
        // When enabled again, reset to default values
        stockController.text = '0';
        minStockController.text = '0';
      }
    });
  }

  void toggleStockTracking(bool enabled) {
    isStockEnabled.value = enabled;

    if (enabled) {
      Get.snackbar(
        'Pelacakan Stok Diaktifkan',
        'Anda dapat mengatur stok dan stok minimum produk',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.inventory, color: Colors.green),
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Pelacakan Stok Dinonaktifkan',
        'Stok produk akan dianggap tidak terbatas',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> loadData() async {
    isLoading.value = true;

    try {
      final [productList, categoryList] = await Future.wait([
        _service.getAllProducts(),
        _categoryService.getAllCategories(),
      ]);

      products.assignAll(productList as Iterable<Product>);
      categories.assignAll(categoryList as Iterable<Category>);
      _transactionController.loadInitialData();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void resetForm() {
    nameController.clear();
    skuController.clear();
    barcodeController.clear();
    costPriceController.clear();
    sellingPriceController.clear();
    unitController.clear();
    stockController.clear();
    minStockController.clear();
    selectedCategoryId.value = null;
    selectedImage.value = null;
    isStockEnabled.value = true;

    // Reset observable values
    costPrice.value = 0.0;
    sellingPrice.value = 0.0;
    stockValue.value = 0;
    minStockValue.value = 0;

    // Reset to default stock values
    _initializeStockControllers();
  }

  Future<void> saveProduct() async {
    try {
      if (!await _validateForm()) return;

      isLoading.value = true;

      // SKU will be auto-generated in service if empty
      final finalSku = skuController.text.trim();

      // Determine stock values based on tracking setting
      final int actualStock = isStockEnabled.value
          ? int.parse(stockController.text)
          : 999999; // Unlimited stock representation

      final int actualMinStock = isStockEnabled.value
          ? int.parse(minStockController.text)
          : 0;

      final savedProduct = await _service.addProduct(
        name: nameController.text.trim(),
        categoryId: selectedCategoryId.value!,
        sku: finalSku,
        barcode: barcodeController.text.trim(),
        costPrice: double.parse(costPriceController.text),
        sellingPrice: double.parse(sellingPriceController.text),
        unit: unitController.text.trim(),
        stock: actualStock,
        minStock: actualMinStock,
        imageFile: selectedImage.value,
        isStockEnabled: isStockEnabled.value,
      );

      await loadData();
      resetForm();
      Get.back();

      Get.snackbar(
        'Berhasil',
        'Produk berhasil ditambahkan\nSKU: ${savedProduct.sku}',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      isLoading.value = true;
      await _service.deleteProduct(id);
      await loadData();
      Get.back();
      Get.snackbar('Sukses', 'Produk berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus produk: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> scanBarcode() async {
    try {
      // Generate a random barcode for demo purposes
      // In real implementation, you would use a barcode scanning library
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      barcodeController.text = '899567${timestamp.substring(timestamp.length - 6)}';

      Get.snackbar(
        'Barcode Generated',
        'Demo barcode: ${barcodeController.text}',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        icon: const Icon(Icons.qr_code, color: Colors.blue),
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal scan barcode: $e');
    }
  }

  Future<void> selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await Get.dialog<ImageSource>(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto dengan kamera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.green.shade700),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri foto'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
          ],
        ),
      );

      if (source != null) {
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 30,
          maxWidth: 1080,
          maxHeight: 1080,
        );

        if (pickedFile != null) {
          selectedImage.value = File(pickedFile.path);
          Get.snackbar(
            'Berhasil',
            'Foto berhasil dipilih',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memilih gambar: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  Future<bool> _validateForm() async {
    // Basic field validation
    if (nameController.text.trim().isEmpty) {
      _showValidationError('Nama produk tidak boleh kosong');
      return false;
    }

    if (selectedCategoryId.value == null || selectedCategoryId.value!.isEmpty) {
      _showValidationError('Pilih kategori produk');
      return false;
    }

    // SKU is now optional - no validation needed

    if (barcodeController.text.trim().isEmpty) {
      _showValidationError('Barcode tidak boleh kosong');
      return false;
    }

    if (costPriceController.text.trim().isEmpty) {
      _showValidationError('Harga modal tidak boleh kosong');
      return false;
    }

    if (sellingPriceController.text.trim().isEmpty) {
      _showValidationError('Harga jual tidak boleh kosong');
      return false;
    }

    if (unitController.text.trim().isEmpty) {
      _showValidationError('Satuan tidak boleh kosong');
      return false;
    }

    // Stock validation only if stock tracking is enabled
    if (isStockEnabled.value) {
      if (stockController.text.trim().isEmpty) {
        _showValidationError('Stok awal tidak boleh kosong');
        return false;
      }

      if (minStockController.text.trim().isEmpty) {
        _showValidationError('Stok minimum tidak boleh kosong');
        return false;
      }
    }

    return await _validateBusinessLogic();
  }

  Future<bool> _validateBusinessLogic() async {
    // Number format validation
    try {
      final costPriceValue = double.parse(costPriceController.text);
      final sellingPriceValue = double.parse(sellingPriceController.text);

      if (costPriceValue < 0) {
        _showValidationError('Harga modal tidak boleh negatif');
        return false;
      }

      if (sellingPriceValue < 0) {
        _showValidationError('Harga jual tidak boleh negatif');
        return false;
      }

      if (sellingPriceValue <= costPriceValue) {
        final result = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Peringatan Harga'),
            content: const Text(
                'Harga jual sama atau lebih rendah dari harga modal.\n'
                    'Ini akan mengakibatkan kerugian atau tidak ada keuntungan.\n\n'
                    'Apakah Anda yakin ingin melanjutkan?'
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        );

        if (result != true) return false;
      }

      // Stock validation if enabled
      if (isStockEnabled.value) {
        final stock = int.parse(stockController.text);
        final minStock = int.parse(minStockController.text);

        if (stock < 0) {
          _showValidationError('Stok tidak boleh negatif');
          return false;
        }

        if (minStock < 0) {
          _showValidationError('Stok minimum tidak boleh negatif');
          return false;
        }
      }

      // SKU uniqueness check only if provided
      if (skuController.text.trim().isNotEmpty) {
        if (await _isSkuExists(skuController.text.trim())) {
          _showValidationError('SKU "${skuController.text.trim()}" sudah digunakan');
          return false;
        }
      }

      // Barcode uniqueness check
      if (await _isBarcodeExists(barcodeController.text.trim())) {
        _showValidationError('Barcode "${barcodeController.text.trim()}" sudah digunakan');
        return false;
      }

    } catch (e) {
      _showValidationError('Format angka tidak valid');
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    Get.snackbar(
      'Validasi Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.warning, color: Colors.red),
      duration: const Duration(seconds: 3),
    );
  }

  // Helper method to format price display
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  // Helper method to calculate profit margin
  double get calculatedProfitMargin {
    if (costPrice.value > 0) {
      return ((sellingPrice.value - costPrice.value) / costPrice.value) * 100;
    }
    return 0.0;
  }

  // Helper method to calculate profit amount
  double get calculatedProfitAmount {
    return sellingPrice.value - costPrice.value;
  }

  // Check if SKU already exists
  Future<bool> _isSkuExists(String sku) async {
    try {
      return await _service.isSkuExists(sku);
    } catch (e) {
      return false;
    }
  }

  // Check if Barcode already exists
  Future<bool> _isBarcodeExists(String barcode) async {
    try {
      return await _service.isBarcodeExists(barcode);
    } catch (e) {
      return false;
    }
  }
}
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
  RxBool isGridView = true.obs;

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
  }

  Future<void> saveProduct() async {
    try {
      if (!_validateForm()) return;

      isLoading.value = true;

      await _service.addProduct(
        name: nameController.text.trim(),
        categoryId: selectedCategoryId.value!,
        sku: skuController.text.trim(),
        barcode: barcodeController.text.trim(),
        costPrice: double.parse(costPriceController.text),
        sellingPrice: double.parse(sellingPriceController.text),
        unit: unitController.text.trim(),
        stock: int.parse(stockController.text),
        minStock: int.parse(minStockController.text),
        imageFile: selectedImage.value,
      );

      await loadData();
      resetForm();
      Get.back();
      Get.snackbar('Sukses', 'Produk berhasil ditambahkan');
    } catch (e) {
      Get.snackbar('Error', e.toString());
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
    // Implement barcode scanning
    try {
      // For demo, generate random barcode
      barcodeController.text = '899567${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    } catch (e) {
      Get.snackbar('Error', 'Gagal scan barcode: $e');
    }
  }

  Future<void> selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
        if (pickedFile != null) {
          selectedImage.value = File(pickedFile.path);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar: $e');
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty ||
        selectedCategoryId.value == null ||
        // skuController.text.trim().isEmpty ||
        barcodeController.text.trim().isEmpty ||
        costPriceController.text.trim().isEmpty ||
        sellingPriceController.text.trim().isEmpty ||
        unitController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty ||
        minStockController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Semua field wajib diisi');
      return false;
    }

    try {
      double.parse(costPriceController.text);
      double.parse(sellingPriceController.text);
      int.parse(stockController.text);
      int.parse(minStockController.text);
    } catch (e) {
      Get.snackbar('Error', 'Format angka tidak valid');
      return false;
    }

    return true;
  }
}

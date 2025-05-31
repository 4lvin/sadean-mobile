import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductController extends GetxController {
  final RxList<Product> products = <Product>[].obs;
  final RxList<Category> categories = <Category>[].obs;

  // For product form
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
    fetchProducts();
    fetchCategories();
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

  void fetchProducts() {
    // Sample products for demonstration
    products.value = [
      Product(
        id: '1',
        name: 'Nasi Goreng',
        categoryId: '1',
        sku: 'NG001',
        barcode: '8995678123456',
        costPrice: 15000,
        sellingPrice: 25000,
        unit: 'porsi',
        stock: 20,
        minStock: 5,
      ),
      Product(
        id: '2',
        name: 'Es Teh Manis',
        categoryId: '2',
        sku: 'ETM001',
        barcode: '8995678123457',
        costPrice: 3000,
        sellingPrice: 8000,
        unit: 'gelas',
        stock: 50,
        minStock: 10,
      ),
      Product(
        id: '3',
        name: 'Ayam Goreng',
        categoryId: '1',
        sku: 'AG001',
        barcode: '8995678123458',
        costPrice: 12000,
        sellingPrice: 20000,
        unit: 'porsi',
        stock: 15,
        minStock: 3,
      ),
    ];
  }

  void fetchCategories() {
    // Sample categories for demonstration
    categories.value = [
      Category(id: '1', name: 'Makanan'),
      Category(id: '2', name: 'Minuman'),
      Category(id: '3', name: 'Snack'),
    ];
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
      if (nameController.text.isEmpty ||
          selectedCategoryId.value == null ||
          skuController.text.isEmpty ||
          barcodeController.text.isEmpty ||
          costPriceController.text.isEmpty ||
          sellingPriceController.text.isEmpty ||
          unitController.text.isEmpty ||
          stockController.text.isEmpty ||
          minStockController.text.isEmpty) {
        Get.snackbar('Error', 'Please fill all required fields');
        return;
      }

      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text,
        categoryId: selectedCategoryId.value!,
        sku: skuController.text,
        barcode: barcodeController.text,
        costPrice: double.parse(costPriceController.text),
        sellingPrice: double.parse(sellingPriceController.text),
        unit: unitController.text,
        stock: int.parse(stockController.text),
        minStock: int.parse(minStockController.text),
        // In a real app, you would upload the image and store its URL
        imageUrl: selectedImage.value != null ? selectedImage.value!.path : null,
      );

      // In a real app, save to database
      products.add(newProduct);
      resetForm();
      Get.back();
      Get.snackbar('Success', 'Product added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save product: ${e.toString()}');
    }
  }

  Future<void> scanBarcode() async {
    // In a real app, this would use a barcode scanner plugin
    // For now, just simulate a scanned barcode
    barcodeController.text = '8995678' + DateTime.now().second.toString().padLeft(6, '0');
  }

  void selectImage() async {
    // In a real app, this would use image_picker to get an image
    // For now, we'll just simulate image selection
    selectedImage.value = File('dummy_path');
    Get.snackbar('Image Selected', 'Image successfully selected');
  }
}

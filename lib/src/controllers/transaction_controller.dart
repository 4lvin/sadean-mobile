import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../service/category_service.dart';
import '../service/product_service.dart';
import '../service/transaction_service.dart';

class TransactionController extends GetxController {
  final TransactionService _service = Get.find<TransactionService>();
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();

  // Cart Management
  final RxList<TransactionItem> cartItems = <TransactionItem>[].obs;
  final RxDouble cartTotal = 0.0.obs;
  final RxDouble cartProfit = 0.0.obs;
  final RxInt cartItemCount = 0.obs;

  // Product Management
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxList<Category> categories = <Category>[].obs;
  final RxString selectedCategoryId = ''.obs;
  final RxString searchQuery = ''.obs;

  // UI States
  final RxBool isLoading = false.obs;
  final RxBool isProcessingTransaction = false.obs;
  final RxBool showCart = false.obs;

  // Search controller
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadInitialData();

    // Listen to search query changes with debounce
    debounce(searchQuery, _performSearch, time: const Duration(milliseconds: 500));

    // Listen to cart changes to update totals
    ever(cartItems, _updateCartTotals);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      final [productList, categoryList] = await Future.wait([
        _productService.getAllProducts(),
        _categoryService.getAllCategories(),
      ]);

      products.assignAll(productList as Iterable<Product>);
      categories.assignAll(categoryList as Iterable<Category>);
      _performSearch(searchQuery.value);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _performSearch(String query) {
    List<Product> filtered = products;

    // Filter by category
    if (selectedCategoryId.value.isNotEmpty) {
      filtered = filtered.where((p) => p.categoryId == selectedCategoryId.value).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where((product) =>
      product.name.toLowerCase().contains(lowerQuery) ||
          product.sku.toLowerCase().contains(lowerQuery) ||
          product.barcode.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    filteredProducts.assignAll(filtered);
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setSelectedCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
    _performSearch(searchQuery.value);
  }

  void clearFilters() {
    selectedCategoryId.value = '';
    searchQuery.value = '';
    searchController.clear();
    _performSearch('');
  }

  // Cart Management Methods
  void addToCart(Product product, {int quantity = 1}) {
    // Check stock availability
    final currentCartQuantity = getCartQuantity(product.id);
    final totalRequestedQuantity = currentCartQuantity + quantity;

    if (totalRequestedQuantity > product.stock) {
      Get.snackbar(
        'Stok Tidak Cukup',
        'Stok: ${product.stock}, Di keranjang: $currentCartQuantity',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.warning, color: Colors.red),
      );
      return;
    }

    final existingIndex = cartItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      // Update existing item
      final existingItem = cartItems[existingIndex];
      cartItems[existingIndex] = TransactionItem(
        productId: product.id,
        productName: product.name,
        quantity: existingItem.quantity + quantity,
        unitPrice: product.sellingPrice,
        costPrice: product.costPrice,
      );
    } else {
      // Add new item
      cartItems.add(TransactionItem(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        costPrice: product.costPrice,
      ));
    }

    // Auto show cart if hidden
    if (!showCart.value) {
      showCart.value = true;
    }

    // Improved feedback with haptic
    Get.snackbar(
      'Ditambahkan',
      '${product.name} x$quantity',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.shopping_cart, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      snackPosition: SnackPosition.TOP,
    );
  }

  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.productId == productId);
    if (cartItems.isEmpty) {
      showCart.value = false;
    }
  }

  void updateCartItemQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    // Get product untuk check stock
    final product = products.firstWhereOrNull((p) => p.id == productId);
    if (product == null) {
      Get.snackbar('Error', 'Produk tidak ditemukan');
      return;
    }

    if (newQuantity > product.stock) {
      Get.snackbar(
        'Stok Tidak Cukup',
        'Stok tersedia: ${product.stock}',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    final index = cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      final item = cartItems[index];
      cartItems[index] = TransactionItem(
        productId: item.productId,
        productName: item.productName,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
        costPrice: item.costPrice,
      );

      // Show feedback
      Get.snackbar(
        'Quantity Updated',
        '${item.productName}: $newQuantity',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 1),
      );
    }
  }

  int getCartQuantity(String productId) {
    final item = cartItems.firstWhereOrNull((item) => item.productId == productId);
    return item?.quantity ?? 0;
  }

  void _updateCartTotals(List<TransactionItem> items) {
    final total = items.fold<double>(0, (sum, item) => sum + (item.quantity * item.unitPrice));
    final profit = items.fold<double>(0, (sum, item) =>
    sum + (item.quantity * (item.unitPrice - item.costPrice)));
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);

    cartTotal.value = total;
    cartProfit.value = profit;
    cartItemCount.value = itemCount;
  }

  void clearCart() {
    cartItems.clear();
    showCart.value = false;
  }

  // Barcode Scanning
  Future<void> scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcode != '-1') {
        await searchProductByBarcode(barcode);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal scan barcode: $e');
    }
  }

  Future<void> searchProductByBarcode(String barcode) async {
    final product = await _productService.getProductByBarcode(barcode);

    if (product != null) {
      if (product.stock > 0) {
        addToCart(product);
      } else {
        Get.snackbar('Stok Habis', '${product.name} tidak tersedia');
      }
    } else {
      Get.snackbar('Produk Tidak Ditemukan', 'Barcode: $barcode');
    }
  }

  // Transaction Processing
  Future<void> processTransaction() async {
    if (cartItems.isEmpty) {
      Get.snackbar('Error', 'Keranjang kosong');
      return;
    }

    try {
      isProcessingTransaction.value = true;

      final transaction = await _service.addTransaction(items: cartItems.toList());

      // Clear cart after successful transaction
      clearCart();

      // Show success dialog with options
      _showTransactionSuccessDialog(transaction);

    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses transaksi: $e');
    } finally {
      isProcessingTransaction.value = false;
    }
  }

  void _showTransactionSuccessDialog(Transaction transaction) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Transaksi Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Transaksi: ${transaction.id}'),
            const SizedBox(height: 8),
            Text('Total: Rp ${formatPrice(transaction.totalAmount)}'),
            const SizedBox(height: 8),
            Text('Laba: Rp ${formatPrice(transaction.profit)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back(); // Return to main screen
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              printReceipt(transaction);
              Get.back(); // Return to main screen
            },
            icon: const Icon(Icons.print),
            label: const Text('Cetak Struk'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void printReceipt(Transaction transaction) {
    Get.snackbar('Info', 'Mencetak struk transaksi ${transaction.id}');
    // Implement actual printing logic here
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // Save current cart (for later use)
  void saveCart() {
    if (cartItems.isEmpty) {
      Get.snackbar('Error', 'Keranjang kosong');
      return;
    }

    // Implement cart saving logic
    Get.snackbar('Info', 'Keranjang disimpan');
  }

  // Quick add product methods
  void quickAddProduct(Product product) {
    _showQuantityDialog(product);
  }

  void _showQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: '1');

    Get.dialog(
      AlertDialog(
        title: Text('Tambah ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok tersedia: ${product.stock} ${product.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 1;
              Get.back();
              addToCart(product, quantity: quantity);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

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
  final RxDouble cartSubtotal = 0.0.obs;
  final RxDouble cartTotal = 0.0.obs;
  final RxDouble cartProfit = 0.0.obs;
  final RxInt cartItemCount = 0.obs;

  // Transaction Adjustments
  final RxDouble shippingCost = 0.0.obs;
  final RxDouble discount = 0.0.obs;
  final RxDouble serviceFee = 0.0.obs;
  final RxDouble tax = 0.0.obs;
  final RxString discountType = 'amount'.obs; // 'amount' or 'percentage'
  final RxString taxType = 'amount'.obs; // 'amount' or 'percentage'

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
    ever(shippingCost, (_) => _updateCartTotals(cartItems));
    ever(discount, (_) => _updateCartTotals(cartItems));
    ever(serviceFee, (_) => _updateCartTotals(cartItems));
    ever(tax, (_) => _updateCartTotals(cartItems));
    ever(discountType, (_) => _updateCartTotals(cartItems));
    ever(taxType, (_) => _updateCartTotals(cartItems));
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
    final subtotal = items.fold<double>(0, (sum, item) => sum + (item.quantity * item.unitPrice));

    // Calculate discount
    double discountAmount = 0;
    if (discountType.value == 'percentage') {
      discountAmount = subtotal * (discount.value / 100);
    } else {
      discountAmount = discount.value;
    }

    // Calculate tax
    double taxAmount = 0;
    final taxableAmount = subtotal - discountAmount + serviceFee.value + shippingCost.value;
    if (taxType.value == 'percentage') {
      taxAmount = taxableAmount * (tax.value / 100);
    } else {
      taxAmount = tax.value;
    }

    final total = subtotal - discountAmount + serviceFee.value + shippingCost.value + taxAmount;

    final costAmount = items.fold<double>(0, (sum, item) => sum + (item.quantity * item.costPrice));
    final profit = total - costAmount;
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);

    cartSubtotal.value = subtotal;
    cartTotal.value = total;
    cartProfit.value = profit;
    cartItemCount.value = itemCount;
  }

  void clearCart() {
    cartItems.clear();
    shippingCost.value = 0;
    discount.value = 0;
    serviceFee.value = 0;
    tax.value = 0;
    showCart.value = false;
  }

  // Transaction Adjustments Dialog
  void showAdjustmentsDialog() {
    final shippingController = TextEditingController(text: shippingCost.value.toString());
    final discountController = TextEditingController(text: discount.value.toString());
    final serviceController = TextEditingController(text: serviceFee.value.toString());
    final taxController = TextEditingController(text: tax.value.toString());

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.tune, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text(
                    'Pengaturan Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Shipping Cost
              _buildAdjustmentField(
                controller: shippingController,
                label: 'Biaya Pengiriman',
                icon: Icons.local_shipping,
                onChanged: (value) {
                  shippingCost.value = double.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),

              // Discount
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildAdjustmentField(
                      controller: discountController,
                      label: 'Diskon',
                      icon: Icons.discount,
                      onChanged: (value) {
                        discount.value = double.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: discountType.value,
                      decoration: const InputDecoration(
                        labelText: 'Tipe',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'amount', child: Text('Rp')),
                        DropdownMenuItem(value: 'percentage', child: Text('%')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          discountType.value = value;
                        }
                      },
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Service Fee
              _buildAdjustmentField(
                controller: serviceController,
                label: 'Biaya Layanan',
                icon: Icons.room_service,
                onChanged: (value) {
                  serviceFee.value = double.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),

              // Tax
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildAdjustmentField(
                      controller: taxController,
                      label: 'Pajak',
                      icon: Icons.receipt_long,
                      onChanged: (value) {
                        tax.value = double.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: taxType.value,
                      decoration: const InputDecoration(
                        labelText: 'Tipe',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'amount', child: Text('Rp')),
                        DropdownMenuItem(value: 'percentage', child: Text('%')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          taxType.value = value;
                        }
                      },
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Obx(() {
                  final subtotal = cartSubtotal.value;
                  final discountAmount = discountType.value == 'percentage'
                      ? subtotal * (discount.value / 100)
                      : discount.value;
                  final taxableAmount = subtotal - discountAmount + serviceFee.value + shippingCost.value;
                  final taxAmount = taxType.value == 'percentage'
                      ? taxableAmount * (tax.value / 100)
                      : tax.value;
                  final total = subtotal - discountAmount + serviceFee.value + shippingCost.value + taxAmount;

                  return Column(
                    children: [
                      _buildPreviewRow('Subtotal', subtotal),
                      if (discount.value > 0)
                        _buildPreviewRow(
                          'Diskon ${discountType.value == 'percentage' ? '(${discount.value}%)' : ''}',
                          -discountAmount,
                          isNegative: true,
                        ),
                      if (serviceFee.value > 0)
                        _buildPreviewRow('Biaya Layanan', serviceFee.value),
                      if (shippingCost.value > 0)
                        _buildPreviewRow('Biaya Pengiriman', shippingCost.value),
                      if (tax.value > 0)
                        _buildPreviewRow(
                          'Pajak ${taxType.value == 'percentage' ? '(${tax.value}%)' : ''}',
                          taxAmount,
                        ),
                      const Divider(),
                      _buildPreviewRow('Total', total, isBold: true),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset values
                        shippingCost.value = 0;
                        discount.value = 0;
                        serviceFee.value = 0;
                        tax.value = 0;
                        Get.back();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.snackbar(
                          'Berhasil',
                          'Pengaturan transaksi telah diperbarui',
                          backgroundColor: Colors.green.shade100,
                          colorText: Colors.green.shade800,
                        );
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustmentField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildPreviewRow(String label, double amount, {bool isNegative = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}Rp ${formatPrice(amount.abs())}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: isNegative ? Colors.red : (isBold ? Colors.black : Colors.grey.shade700),
          ),
        ),
      ],
    );
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

      // Calculate final amounts for transaction
      final discountAmount = discountType.value == 'percentage'
          ? cartSubtotal.value * (discount.value / 100)
          : discount.value;

      final taxableAmount = cartSubtotal.value - discountAmount + serviceFee.value + shippingCost.value;
      final taxAmount = taxType.value == 'percentage'
          ? taxableAmount * (tax.value / 100)
          : tax.value;

      final transaction = await _service.addTransaction(
        items: cartItems.toList(),
        discount: discountAmount,
        tax: taxAmount,
        shippingCost: shippingCost.value,
        serviceFee: serviceFee.value,
      );

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

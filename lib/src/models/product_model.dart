class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? imageUrl; // Now stores file path
  final String sku;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final String unit;
  final int stock;
  final int minStock;
  final int soldCount;
  final bool isStockEnabled; // New field for stock tracking toggle

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.imageUrl,
    required this.sku,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.unit,
    required this.stock,
    required this.minStock,
    this.soldCount = 0,
    this.isStockEnabled = true, // Default to enabled
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category_id': categoryId,
    'image_url': imageUrl,
    'sku': sku,
    'barcode': barcode,
    'cost_price': costPrice,
    'selling_price': sellingPrice,
    'unit': unit,
    'stock': stock,
    'min_stock': minStock,
    'sold_count': soldCount,
    'is_stock_enabled': isStockEnabled,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    categoryId: json['category_id'],
    imageUrl: json['image_url'],
    sku: json['sku'],
    barcode: json['barcode'],
    costPrice: json['cost_price'].toDouble(),
    sellingPrice: json['selling_price'].toDouble(),
    unit: json['unit'],
    stock: json['stock'],
    minStock: json['min_stock'],
    soldCount: json['sold_count'] ?? 0,
    isStockEnabled: (json['is_stock_enabled'] ?? 1) == 1,
  );

  // Helper methods

  /// Calculate profit per unit
  double get profitPerUnit => sellingPrice - costPrice;

  /// Calculate profit margin percentage
  double get profitMargin => costPrice > 0 ? (profitPerUnit / costPrice) * 100 : 0;

  /// Check if product is low on stock (only for stock-enabled products)
  bool get isLowStock => isStockEnabled && stock <= minStock && stock > 0;

  /// Check if product is out of stock (only for stock-enabled products)
  bool get isOutOfStock => isStockEnabled && stock == 0;

  /// Check if product has unlimited stock
  bool get hasUnlimitedStock => !isStockEnabled;

  /// Get stock status as string
  String get stockStatus {
    if (!isStockEnabled) return 'Unlimited';
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Get display stock text
  String get stockDisplay {
    if (!isStockEnabled) return 'Unlimited';
    return '$stock $unit';
  }

  /// Check if product can be sold
  bool canSell([int quantity = 1]) {
    if (!isStockEnabled) return true; // Unlimited stock
    return stock >= quantity;
  }

  /// Get available quantity that can be sold
  int get availableQuantity {
    if (!isStockEnabled) return 999999; // Unlimited
    return stock;
  }

  /// Copy with method for easy updates
  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? imageUrl,
    String? sku,
    String? barcode,
    double? costPrice,
    double? sellingPrice,
    String? unit,
    int? stock,
    int? minStock,
    int? soldCount,
    bool? isStockEnabled,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      soldCount: soldCount ?? this.soldCount,
      isStockEnabled: isStockEnabled ?? this.isStockEnabled,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, sku: $sku, stock: $stockDisplay, isStockEnabled: $isStockEnabled}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}
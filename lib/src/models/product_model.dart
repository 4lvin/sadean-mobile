class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? imageUrl; // Now stores Base64 string
  final String sku;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final String unit;
  final int stock;
  final int minStock;
  final int soldCount;

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
  );
}
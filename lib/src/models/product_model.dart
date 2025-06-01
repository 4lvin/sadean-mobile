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
    'categoryId': categoryId,
    'imageUrl': imageUrl,
    'sku': sku,
    'barcode': barcode,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'unit': unit,
    'stock': stock,
    'minStock': minStock,
    'soldCount': soldCount,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    categoryId: json['categoryId'],
    imageUrl: json['imageUrl'],
    sku: json['sku'],
    barcode: json['barcode'],
    costPrice: json['costPrice'].toDouble(),
    sellingPrice: json['sellingPrice'].toDouble(),
    unit: json['unit'],
    stock: json['stock'],
    minStock: json['minStock'],
    soldCount: json['soldCount'] ?? 0,
  );
}
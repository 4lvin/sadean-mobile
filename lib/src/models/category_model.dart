class Category {
  final String id;
  final String name;
  final int productCount;
  final int soldCount;

  Category({
    required this.id,
    required this.name,
    this.productCount = 0,
    this.soldCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'productCount': productCount,
    'soldCount': soldCount,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    productCount: json['productCount'] ?? 0,
    soldCount: json['soldCount'] ?? 0,
  );
}
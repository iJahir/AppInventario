class ProductModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? category;
  final String? imageUrl;
  final String? sku;
  final double? purchasePrice;
  final double? taxPercentage;
  final String? unitMeasure;
  final int? minStock;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.category,
    this.imageUrl,
    this.sku,
    this.purchasePrice,
    this.taxPercentage,
    this.unitMeasure,
    this.minStock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      category: json['category'],
      imageUrl: json['imageUrl'],
      sku: json['sku'],
      purchasePrice: json['purchasePrice'] != null ? (json['purchasePrice'] as num).toDouble() : null,
      taxPercentage: json['taxPercentage'] != null ? (json['taxPercentage'] as num).toDouble() : null,
      unitMeasure: json['unitMeasure'],
      minStock: json['minStock'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrl': imageUrl,
      'sku': sku,
      'purchasePrice': purchasePrice,
      'taxPercentage': taxPercentage,
      'unitMeasure': unitMeasure,
      'minStock': minStock,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
    String? sku,
    double? purchasePrice,
    double? taxPercentage,
    String? unitMeasure,
    int? minStock,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      unitMeasure: unitMeasure ?? this.unitMeasure,
      minStock: minStock ?? this.minStock,
    );
  }
}

import 'product.dart';

class Favorite {
  final int id;
  final int productId;
  final DateTime createdAt;
  final Product product;

  Favorite({
    required this.id,
    required this.productId,
    required this.createdAt,
    required this.product,
  });

  // Convertir JSON en objet Favorite
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      productId: json['productId'],
      createdAt: DateTime.parse(json['createdAt']),
      product: Product.fromJson(json['product']),
    );
  }

  // Convertir objet Favorite en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
      'product': product.toJson(),
    };
  }

  @override
  String toString() {
    return 'Favorite{id: $id, productId: $productId, createdAt: $createdAt}';
  }
} 
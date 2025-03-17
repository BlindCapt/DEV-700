/// Modèle pour représenter un produit
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String barcode;
  final String brand;
  final String category;
  final int quantity;
  final int threshold;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.barcode,
    required this.brand,
    required this.category,
    required this.quantity,
    required this.threshold,
  });

  // Factory pour créer un produit à partir d'un JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      threshold: json['threshold'] as int? ?? 0,
    );
  }

  // Méthode pour convertir un produit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'threshold': threshold,
    };
  }

  // Cloner un produit avec des propriétés modifiées
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? barcode,
    String? brand,
    String? category,
    int? quantity,
    int? threshold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
    );
  }
} 
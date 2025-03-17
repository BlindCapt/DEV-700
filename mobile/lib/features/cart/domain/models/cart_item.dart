import 'package:hive/hive.dart';

// Cette annotation sera utilisée lors de la génération de l'adaptateur Hive
// @HiveType(typeId: 1)
class CartItem {
  // @HiveField(0)
  final int id;
  
  // @HiveField(1)
  final String name;
  
  // @HiveField(2)
  final String imageUrl;
  
  // @HiveField(3)
  final double price;
  
  // @HiveField(4)
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  // Calcul du sous-total pour cet article
  double get subtotal => price * quantity;

  // Pour augmenter la quantité
  void incrementQuantity() {
    quantity++;
  }

  // Pour diminuer la quantité
  bool decrementQuantity() {
    if (quantity > 1) {
      quantity--;
      return true;
    }
    return false; // Retourne false si la quantité est déjà à 1
  }

  // Pour créer une copie avec des propriétés modifiées
  CartItem copyWith({
    int? id,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Remarque: Pour utiliser Hive avec cette classe, vous devez:
// 1. Décommenter les annotations @HiveType et @HiveField
// 2. Exécuter le générateur de code Hive avec:
//    flutter pub run build_runner build
// 3. Enregistrer l'adaptateur dans votre fonction main:
//    Hive.registerAdapter(CartItemAdapter()); 
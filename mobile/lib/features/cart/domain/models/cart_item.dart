import '../../../products/domain/models/product.dart';

// Cette annotation sera utilisée lors de la génération de l'adaptateur Hive
// @HiveType(typeId: 1)
class CartItem {
  // @HiveField(0)
  final Product product;
  
  // @HiveField(1)
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  // Prix total de cet article (prix unitaire * quantité)
  double get totalPrice => product.price * quantity;

  // Créer une copie de cet article avec une nouvelle quantité
  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
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
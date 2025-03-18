import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/cart/domain/models/cart_item.dart';
import '../features/products/domain/models/product.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

// État du panier
class CartState {
  final List<CartItem> items;
  final double totalPrice;
  
  CartState({
    this.items = const [],
  }) : totalPrice = items.fold(0, (sum, item) => sum + item.totalPrice);
  
  // Créer une copie de l'état avec de nouveaux items
  CartState copyWith({List<CartItem>? items}) {
    return CartState(
      items: items ?? this.items,
    );
  }
}

// Notifier pour gérer l'état du panier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());
  
  // Sauvegarder le panier dans Hive
  Future<void> _saveCart() async {
    // La logique de sauvegarde sera implémentée plus tard
  }

  // Charger le panier depuis Hive
  Future<void> _loadCart() async {
    // La logique de chargement sera implémentée plus tard
  }
  
  // Ajouter un produit au panier
  void addToCart(Product product, int quantity) {
    // Vérifier si le produit est déjà dans le panier
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Le produit existe déjà, augmenter la quantité
      final existingItem = state.items[existingIndex];
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity
      );
      
      state = state.copyWith(items: updatedItems);
    } else {
      // Le produit n'existe pas encore, l'ajouter
      final newItem = CartItem(
        product: product,
        quantity: quantity,
      );
      
      state = state.copyWith(
        items: [...state.items, newItem]
      );
    }
    
    debugPrint('Produit ajouté au panier: ${product.name}, quantité: $quantity');
    debugPrint('Panier actuel: ${state.items.length} articles, total: ${state.totalPrice}€');
    _saveCart();
  }
  
  // Modifier la quantité d'un produit dans le panier
  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      // Si la quantité est 0 ou négative, supprimer l'article
      removeFromCart(product);
      return;
    }
    
    final updatedItems = state.items.map((item) {
      if (item.product.id == product.id) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
    _saveCart();
  }
  
  // Supprimer un produit du panier
  void removeFromCart(Product product) {
    final updatedItems = state.items.where((item) => item.product.id != product.id).toList();
    state = state.copyWith(items: updatedItems);
    _saveCart();
  }
  
  // Vider le panier
  void clearCart() {
    state = CartState();
    _saveCart();
  }
}

// Provider pour l'état du panier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
}); 
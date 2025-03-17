import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../features/cart/domain/models/cart_item.dart';

// État du panier
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  // Calcul du total du panier
  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  // Nombre d'articles dans le panier
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Pour créer une copie avec des propriétés modifiées
  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier pour gérer l'état du panier
class CartNotifier extends StateNotifier<CartState> {
  final Box? cartBox;

  CartNotifier({this.cartBox}) : super(CartState()) {
    // Charger le panier depuis Hive si disponible
    _loadCart();
  }

  // Charger le panier depuis Hive
  Future<void> _loadCart() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (cartBox != null) {
        final cartData = cartBox!.get(AppConstants.cartBoxName);
        if (cartData != null && cartData is List) {
          final items = cartData.map((item) => item as CartItem).toList();
          state = state.copyWith(items: items, isLoading: false);
        } else {
          state = state.copyWith(items: [], isLoading: false);
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement du panier: $e',
      );
    }
  }

  // Sauvegarder le panier dans Hive
  Future<void> _saveCart() async {
    try {
      if (cartBox != null) {
        await cartBox!.put(AppConstants.cartBoxName, state.items);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la sauvegarde du panier: $e',
      );
    }
  }

  // Ajouter un article au panier
  void addItem(CartItem item) {
    final currentItems = [...state.items];
    final existingItemIndex = currentItems.indexWhere((i) => i.id == item.id);

    if (existingItemIndex >= 0) {
      // L'article existe déjà, augmenter la quantité
      currentItems[existingItemIndex].incrementQuantity();
    } else {
      // Nouvel article, l'ajouter au panier
      currentItems.add(item);
    }

    state = state.copyWith(items: currentItems);
    _saveCart();
  }

  // Supprimer un article du panier
  void removeItem(int itemId) {
    final currentItems = [...state.items];
    currentItems.removeWhere((item) => item.id == itemId);

    state = state.copyWith(items: currentItems);
    _saveCart();
  }

  // Mettre à jour la quantité d'un article
  void updateQuantity(int itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final currentItems = [...state.items];
    final existingItemIndex = currentItems.indexWhere((i) => i.id == itemId);

    if (existingItemIndex >= 0) {
      final updatedItem = currentItems[existingItemIndex].copyWith(quantity: quantity);
      currentItems[existingItemIndex] = updatedItem;

      state = state.copyWith(items: currentItems);
      _saveCart();
    }
  }

  // Vider le panier
  void clearCart() {
    state = state.copyWith(items: []);
    _saveCart();
  }
}

// Provider pour le panier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  // Vous devrez initialiser Hive et ouvrir la boîte avant d'utiliser ce provider
  // La boîte peut être passée ici si elle est ouverte dans la fonction main
  final box = Hive.box<dynamic>(AppConstants.cartBoxName);
  return CartNotifier(cartBox: box);
}); 
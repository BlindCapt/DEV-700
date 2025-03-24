import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/cart/domain/models/cart_item.dart';
import '../features/products/domain/models/product.dart';
import '../features/cart/data/api/cart_api_service.dart';
import '../core/utils/token_manager.dart';
import 'auth_provider.dart';

// État du panier
class CartState {
  final List<CartItem> items;
  final double totalPrice;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshed;
  
  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastRefreshed,
  }) : totalPrice = items.fold(0, (sum, item) => sum + item.totalPrice);
  
  // Créer une copie de l'état avec de nouveaux items
  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
    DateTime? lastRefreshed,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }
}

// Notifier pour gérer l'état du panier
class CartNotifier extends StateNotifier<CartState> {
  final CartApiService _cartApiService;
  final TokenManager _tokenManager;
  final Ref _ref;
  
  CartNotifier(this._ref) : 
    _cartApiService = _ref.read(cartApiServiceProvider),
    _tokenManager = TokenManager(),
    super(CartState()) {
    // Écouter les changements d'état d'authentification
    _listenToAuthChanges();
  }
  
  // Écouter les changements d'état d'authentification
  void _listenToAuthChanges() {
    _ref.listen(authProvider, (previous, next) {
      // Si l'utilisateur vient de se connecter, charger le panier
      if (previous?.isAuthenticated == false && next.isAuthenticated == true) {
        debugPrint('Détection de connexion utilisateur, chargement du panier');
        refreshCart();
      }
      // Si l'utilisateur vient de se déconnecter, vider le panier local
      else if (previous?.isAuthenticated == true && next.isAuthenticated == false) {
        debugPrint('Détection de déconnexion utilisateur, vidage du panier local');
        state = CartState();
      }
    });
  }
  
  // Vérifier l'authentification avec plusieurs tentatives
  Future<bool> _checkAuthWithRetry() async {
    // Première tentative
    var isAuthenticated = await _tokenManager.isAuthenticated();
    
    // Si l'authentification échoue, vérifier si l'état auth indique que l'utilisateur est authentifié
    if (!isAuthenticated) {
      final authState = _ref.read(authProvider);
      
      if (authState.isAuthenticated) {
        debugPrint('État d\'authentification incohérent, tentative de restauration du token');
        // Attendre un court instant avant de réessayer
        await Future.delayed(const Duration(milliseconds: 200));
        isAuthenticated = await _tokenManager.isAuthenticated();
      }
    }
    
    if (!isAuthenticated) {
      debugPrint('Utilisateur non authentifié après vérification approfondie');
    }
    
    return isAuthenticated;
  }
  
  // Charger le panier depuis l'API
  Future<void> _loadCart() async {
    try {
      // Vérifier si l'utilisateur est authentifié avec plusieurs tentatives
      final isAuthenticated = await _checkAuthWithRetry();
      if (!isAuthenticated) {
        debugPrint('Utilisateur non authentifié, impossible de charger le panier');
        return;
      }
      
      // Mettre à jour l'état pour indiquer le chargement
      state = state.copyWith(isLoading: true);
      
      // Récupérer le panier depuis l'API
      final cartItems = await _cartApiService.fetchCart();
      
      // Mettre à jour l'état avec les articles récupérés
      state = state.copyWith(
        items: cartItems,
        isLoading: false,
        error: null,
      );
      
      debugPrint('Panier chargé: ${cartItems.length} articles');
    } catch (e) {
      // En cas d'erreur, mettre à jour l'état avec le message d'erreur
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement du panier: $e',
      );
      debugPrint('Erreur lors du chargement du panier: $e');
    }
  }
  
  // Ajouter un produit au panier avec une quantité donnée
  Future<void> addToCart(Product product, int quantity) async {
    try {
      // Vérifier si l'utilisateur est authentifié avec plusieurs tentatives
      final isAuthenticated = await _checkAuthWithRetry();
      if (!isAuthenticated) {
        debugPrint('Utilisateur non authentifié, impossible d\'ajouter au panier');
        state = state.copyWith(
          error: 'Vous devez être connecté pour ajouter des produits au panier',
        );
        return;
      }
      
      // Mettre à jour l'état local d'abord pour une réponse immédiate
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
      
      // Puis synchroniser avec l'API
      final success = await _cartApiService.addToCart(product.id, quantity);
      
      if (!success) {
        // Si la synchronisation échoue, recharger le panier complet
        await _loadCart();
        debugPrint('Échec de la synchronisation, panier rechargé');
      }
      
      debugPrint('Produit ajouté au panier: ${product.name}, quantité: $quantity');
      debugPrint('Panier actuel: ${state.items.length} articles, total: ${state.totalPrice}€');
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de l\'ajout au panier: $e',
      );
      debugPrint('Erreur lors de l\'ajout au panier: $e');
    }
  }
  
  // Ajouter un produit au panier (quantité 1)
  Future<void> addItemToCart(Product product) async {
    await addToCart(product, 1);
  }
  
  // Modifier la quantité d'un produit dans le panier
  Future<void> updateQuantity(Product product, int quantity) async {
    try {
      // Vérifier si l'utilisateur est authentifié avec plusieurs tentatives
      final isAuthenticated = await _checkAuthWithRetry();
      if (!isAuthenticated) {
        debugPrint('Utilisateur non authentifié, impossible de mettre à jour le panier');
        state = state.copyWith(
          error: 'Vous devez être connecté pour modifier votre panier',
        );
        return;
      }
      
      if (quantity <= 0) {
        // Si la quantité est 0 ou négative, supprimer l'article
        await removeFromCart(product);
        return;
      }
      
      // Mettre à jour l'état local d'abord
      final updatedItems = state.items.map((item) {
        if (item.product.id == product.id) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      
      state = state.copyWith(items: updatedItems);
      
      // Puis synchroniser avec l'API
      final success = await _cartApiService.updateCartItem(product.id, quantity);
      
      if (!success) {
        // Si la synchronisation échoue, recharger le panier complet
        await _loadCart();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la mise à jour du panier: $e',
      );
      debugPrint('Erreur lors de la mise à jour du panier: $e');
    }
  }
  
  // Supprimer un produit du panier
  Future<void> removeFromCart(Product product) async {
    try {
      // Vérifier si l'utilisateur est authentifié avec plusieurs tentatives
      final isAuthenticated = await _checkAuthWithRetry();
      if (!isAuthenticated) {
        debugPrint('Utilisateur non authentifié, impossible de supprimer du panier');
        state = state.copyWith(
          error: 'Vous devez être connecté pour modifier votre panier',
        );
        return;
      }
      
      // Mettre à jour l'état local d'abord
      final updatedItems = state.items.where((item) => item.product.id != product.id).toList();
      state = state.copyWith(items: updatedItems);
      
      // Puis synchroniser avec l'API
      final success = await _cartApiService.removeFromCart(product.id);
      
      if (!success) {
        // Si la synchronisation échoue, recharger le panier complet
        await _loadCart();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la suppression du panier: $e',
      );
      debugPrint('Erreur lors de la suppression du panier: $e');
    }
  }
  
  // Vider le panier
  Future<void> clearCart() async {
    try {
      // Vérifier si l'utilisateur est authentifié avec plusieurs tentatives
      final isAuthenticated = await _checkAuthWithRetry();
      if (!isAuthenticated) {
        debugPrint('Utilisateur non authentifié, impossible de vider le panier');
        state = state.copyWith(
          error: 'Vous devez être connecté pour vider votre panier',
        );
        return;
      }
      
      // Mettre à jour l'état local d'abord
      state = CartState();
      
      // Puis synchroniser avec l'API
      final success = await _cartApiService.clearCart();
      
      if (!success) {
        // Si la synchronisation échoue, recharger le panier complet
        await _loadCart();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors du vidage du panier: $e',
      );
      debugPrint('Erreur lors du vidage du panier: $e');
    }
  }
  
  // Rafraîchir le panier
  Future<void> refreshCart() async {
    debugPrint('Demande de rafraîchissement du panier');
    
    // Vérifier s'il y a eu un rafraîchissement récent (dans les 2 dernières secondes)
    if (state.lastRefreshed != null) {
      final timeSinceLastRefresh = DateTime.now().difference(state.lastRefreshed!);
      if (timeSinceLastRefresh.inSeconds < 2) {
        debugPrint('Rafraîchissement du panier ignoré - trop récent (${timeSinceLastRefresh.inMilliseconds}ms)');
        return;
      }
    }
    
    try {
      final isAuthenticated = await _checkAuthWithRetry();
      if (!isAuthenticated) {
        state = state.copyWith(
          error: 'Vous devez être connecté pour accéder à votre panier',
          isLoading: false,
        );
        return;
      }
      
      state = state.copyWith(isLoading: true, error: null);
      await _loadCart();
      
      // Enregistrer l'heure du dernier rafraîchissement
      state = state.copyWith(lastRefreshed: DateTime.now());
      debugPrint('Panier rafraîchi avec succès: ${state.items.length} articles');
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du panier: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du rafraîchissement du panier: $e',
      );
    }
  }
}

// Provider pour l'état du panier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
}); 
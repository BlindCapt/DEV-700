import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/products/data/api/favorite_api_service.dart';
import '../features/products/domain/models/favorite.dart';
import '../features/products/domain/models/product.dart';
import 'auth_provider.dart';

// État pour gérer les favoris
class FavoriteState {
  final bool isLoading;
  final String? error;
  final List<Favorite> favorites;
  final Map<int, bool> productFavoriteStatus; // Map pour suivre le statut de favori de chaque produit
  final bool hasLoadedOnce; // Indique si un chargement a déjà été tenté

  FavoriteState({
    this.isLoading = false,
    this.error,
    this.favorites = const [],
    this.productFavoriteStatus = const {},
    this.hasLoadedOnce = false,
  });

  FavoriteState copyWith({
    bool? isLoading,
    String? error,
    List<Favorite>? favorites,
    Map<int, bool>? productFavoriteStatus,
    bool? hasLoadedOnce,
  }) {
    return FavoriteState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      favorites: favorites ?? this.favorites,
      productFavoriteStatus: productFavoriteStatus ?? this.productFavoriteStatus,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}

// Provider pour le service de favoris
final favoriteApiServiceProvider = Provider<FavoriteApiService>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  return FavoriteApiService(authService);
});

// Notifier pour gérer l'état des favoris
class FavoriteNotifier extends StateNotifier<FavoriteState> {
  final FavoriteApiService _favoriteService;

  FavoriteNotifier(this._favoriteService) : super(FavoriteState());

  // Récupérer tous les favoris de l'utilisateur
  Future<void> fetchUserFavorites() async {
    debugPrint('Récupération des favoris utilisateur');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final favorites = await _favoriteService.getUserFavorites();
      
      // Mettre à jour le statut de favori pour chaque produit
      final Map<int, bool> statusMap = {};
      for (var favorite in favorites) {
        statusMap[favorite.productId] = true;
      }

      state = state.copyWith(
        isLoading: false,
        favorites: favorites,
        productFavoriteStatus: statusMap,
        hasLoadedOnce: true,
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération des favoris: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la récupération des favoris: $e',
        hasLoadedOnce: true,
      );
    }
  }

  // Vérifier si un produit est dans les favoris
  Future<bool> checkFavorite(int productId) async {
    // Si nous avons déjà le statut en cache, l'utiliser
    if (state.productFavoriteStatus.containsKey(productId)) {
      return state.productFavoriteStatus[productId]!;
    }

    try {
      final isFavorite = await _favoriteService.checkFavorite(productId);
      
      // Mettre à jour le cache
      final updatedStatus = Map<int, bool>.from(state.productFavoriteStatus);
      updatedStatus[productId] = isFavorite;
      
      state = state.copyWith(productFavoriteStatus: updatedStatus);
      return isFavorite;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du favori: $e');
      return false;
    }
  }

  // Ajouter un produit aux favoris
  Future<bool> addToFavorites(Product product) async {
    try {
      final success = await _favoriteService.addToFavorites(product.id);
      
      if (success) {
        // Mise à jour du statut de favori
        final updatedStatus = Map<int, bool>.from(state.productFavoriteStatus);
        updatedStatus[product.id] = true;
        
        // Créer un nouvel objet Favorite pour l'ajouter à la liste
        final newFavorite = Favorite(
          id: 0, // ID temporaire, sera remplacé lors de la prochaine récupération
          productId: product.id,
          createdAt: DateTime.now(),
          product: product,
        );
        
        // Mise à jour de la liste des favoris
        final updatedFavorites = List<Favorite>.from(state.favorites)..add(newFavorite);
        
        state = state.copyWith(
          favorites: updatedFavorites,
          productFavoriteStatus: updatedStatus,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  // Supprimer un produit des favoris
  Future<bool> removeFromFavorites(int productId) async {
    try {
      final success = await _favoriteService.removeFromFavorites(productId);
      
      if (success) {
        // Mise à jour du statut de favori
        final updatedStatus = Map<int, bool>.from(state.productFavoriteStatus);
        updatedStatus[productId] = false;
        
        // Suppression du favori de la liste
        final updatedFavorites = state.favorites.where((f) => f.productId != productId).toList();
        
        state = state.copyWith(
          favorites: updatedFavorites,
          productFavoriteStatus: updatedStatus,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du favori: $e');
      return false;
    }
  }

  // Toggle favori (ajouter ou supprimer)
  Future<bool> toggleFavorite(Product product) async {
    final isFavorite = state.productFavoriteStatus[product.id] ?? false;
    
    if (isFavorite) {
      return await removeFromFavorites(product.id);
    } else {
      return await addToFavorites(product);
    }
  }
}

// Provider pour l'état des favoris
final favoriteProvider = StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  final favoriteService = ref.watch(favoriteApiServiceProvider);
  return FavoriteNotifier(favoriteService);
}); 
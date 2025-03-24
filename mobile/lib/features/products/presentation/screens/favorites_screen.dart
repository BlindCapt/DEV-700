import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/products/domain/models/favorite.dart';
import 'package:mobile/providers/favorite_provider.dart';
import 'package:mobile/providers/cart_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteState = ref.watch(favoriteProvider);
    
    // Charger les favoris si ce n'est pas déjà fait
    if (!favoriteState.hasLoadedOnce && !favoriteState.isLoading) {
      // Utiliser Future.microtask pour éviter de déclencher setState pendant le build
      Future.microtask(() => ref.read(favoriteProvider.notifier).fetchUserFavorites());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(favoriteProvider.notifier).fetchUserFavorites();
            },
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(context, favoriteState, ref),
    );
  }
  
  Widget _buildBody(BuildContext context, FavoriteState favoriteState, WidgetRef ref) {
    if (favoriteState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des favoris...'),
          ],
        ),
      );
    }
    
    if (favoriteState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                favoriteState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(favoriteProvider.notifier).fetchUserFavorites();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    if (favoriteState.favorites.isEmpty && favoriteState.hasLoadedOnce) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Vous n\'avez pas encore de favoris',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des produits à vos favoris en cliquant sur l\'icône ❤️',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Retourner à l'accueil et sélectionner l'onglet Home (index 0)
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Explorer les produits'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    // Afficher la liste des favoris
    return RefreshIndicator(
      onRefresh: () => ref.read(favoriteProvider.notifier).fetchUserFavorites(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: favoriteState.favorites.length,
        itemBuilder: (context, index) {
          final favorite = favoriteState.favorites[index];
          return _buildFavoriteItem(context, favorite, ref);
        },
      ),
    );
  }
  
  Widget _buildFavoriteItem(BuildContext context, Favorite favorite, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: favorite.product.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(
                  favorite.product.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
        title: Text(
          favorite.product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(favorite.product.brand),
            Text(
              '${favorite.product.price.toStringAsFixed(2)} €',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                ref.read(cartProvider.notifier).addItemToCart(favorite.product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${favorite.product.name} ajouté au panier'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final success = await ref.read(favoriteProvider.notifier).removeFromFavorites(favorite.productId);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${favorite.product.name} retiré des favoris'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 
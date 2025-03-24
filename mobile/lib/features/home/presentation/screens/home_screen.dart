import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/features/auth/data/api/auth_api_service.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/providers/favorite_provider.dart';
import 'package:mobile/features/home/presentation/widgets/social_feed_item.dart';
import 'package:mobile/features/home/presentation/widgets/category_filter.dart';

// Provider pour la catégorie sélectionnée
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final authService = ref.read(authApiServiceProvider);
    final productState = ref.watch(productProvider);
    final productNotifier = ref.read(productProvider.notifier);
    final favoriteNotifier = ref.read(favoriteProvider.notifier);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    // Charger les produits et les favoris si ce n'est pas déjà fait
    _loadDataIfNeeded(productState, productNotifier, favoriteNotifier);
    
    // Fonction de déconnexion qui utilise la méthode mise à jour
    void logout() async {
      await authNotifier.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
    
    // Fonction pour afficher la boîte de dialogue de mise à jour d'URL ngrok
    void _showNgrokUpdateDialog() {
      final TextEditingController ngrokUrlController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mettre à jour l\'URL ngrok'),
          content: TextField(
            controller: ngrokUrlController,
            decoration: const InputDecoration(
              labelText: 'Nouvelle URL ngrok',
              hintText: 'https://votre-url.ngrok.io'
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (ngrokUrlController.text.isNotEmpty) {
                  // Mise à jour de l'URL
                  await authService.updateNgrokUrl(ngrokUrlController.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('URL ngrok mise à jour: ${ngrokUrlController.text}'))
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEV-700 Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Configurer URL ngrok',
            onPressed: _showNgrokUpdateDialog,
          ),
        ],
      ),
      body: _buildBody(context, productState, selectedCategory, ref),
    );
  }
  
  // Charger les produits et les favoris si ce n'est pas déjà fait
  void _loadDataIfNeeded(ProductState productState, ProductNotifier productNotifier, FavoriteNotifier favoriteNotifier) {
    if (productState.products.isEmpty && !productState.isLoading) {
      // Utiliser Future.microtask pour éviter de déclencher setState pendant le build
      Future.microtask(() => productNotifier.fetchAllProducts());
    }
    
    // Charger les favoris
    Future.microtask(() => favoriteNotifier.fetchUserFavorites());
  }
  
  // Construire le corps de la page
  Widget _buildBody(BuildContext context, ProductState productState, String? selectedCategory, WidgetRef ref) {
    if (productState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des produits...'),
          ],
        ),
      );
    }
    
    if (productState.error != null) {
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
                productState.error!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(productProvider.notifier).fetchAllProducts();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (productState.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    // Filtrer les produits par catégorie si nécessaire
    final filteredProducts = selectedCategory == null 
        ? productState.products 
        : productState.products.where((p) => p.category == selectedCategory).toList();
    
    // Afficher le flux social des produits
    return Column(
      children: [
        // Filtre de catégorie
        if (productState.categories.isNotEmpty)
          CategoryFilter(
            categories: productState.categories,
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
          ),
        
        // Liste de produits
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(productProvider.notifier).fetchAllProducts();
              await ref.read(favoriteProvider.notifier).fetchUserFavorites();
            },
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun produit dans cette catégorie',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(selectedCategoryProvider.notifier).state = null;
                          },
                          child: const Text('Voir tous les produits'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8), // Padding réduit, plus besoin d'espace pour le FAB
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 éléments par ligne
                      childAspectRatio: 0.7, // Rapport hauteur/largeur
                      crossAxisSpacing: 4, // Espacement horizontal
                      mainAxisSpacing: 4, // Espacement vertical
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      
                      return SocialFeedItem(
                        product: product,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
} 
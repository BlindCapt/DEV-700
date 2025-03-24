import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/products/domain/models/product.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/favorite_provider.dart';

class SocialFeedItem extends ConsumerWidget {
  final Product product;

  const SocialFeedItem({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteState = ref.watch(favoriteProvider);
    final isFavorite = favoriteState.productFavoriteStatus[product.id] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image du produit (priorité à l'image)
          _buildImage(context),
          
          // Titre et prix du produit
          _buildContent(context),
          
          // Ligne d'actions (favoris, ajouter au panier)
          _buildActionsRow(context, ref, isFavorite),
        ],
      ),
    );
  }
  
  Widget _buildImage(BuildContext context) {
    return Stack(
      children: [
        // Image principale
        AspectRatio(
          aspectRatio: 1.0,
          child: product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
        ),
        // Badge de marque en haut à gauche
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              product.brand.isEmpty ? "?" : product.brand,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du produit
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Prix
          Text(
            '${product.price.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionsRow(BuildContext context, WidgetRef ref, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Favoris
          InkWell(
            onTap: () async {
              final success = await ref.read(favoriteProvider.notifier).toggleFavorite(product);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite 
                        ? '${product.name} retiré des favoris' 
                        : '${product.name} ajouté aux favoris'
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
                size: 24,
              ),
            ),
          ),
          
          // Bouton d'ajout au panier
          SizedBox(
            height: 36,
            width: 36,
            child: FloatingActionButton(
              heroTag: "btn_${product.id}",
              onPressed: () {
                ref.read(cartProvider.notifier).addItemToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} ajouté au panier'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              backgroundColor: Colors.green,
              elevation: 0,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              mini: true,
              child: const Icon(Icons.add_shopping_cart, size: 18),
            ),
          ),
        ],
      ),
    );
  }
} 
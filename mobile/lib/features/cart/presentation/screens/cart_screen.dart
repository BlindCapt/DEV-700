import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/cart_provider.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart'; // Import pour selectedNavIndexProvider
import '../../domain/models/cart_item.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Charger le panier après le rendu initial du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCart();
    });
  }

  void _refreshCart() {
    debugPrint('Rafraîchissement automatique du panier demandé');
    ref.read(cartProvider.notifier).refreshCart();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState.items;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                _showClearCartDialog(context, ref);
              },
              tooltip: 'Vider le panier',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCart,
            tooltip: 'Rafraîchir le panier',
          ),
        ],
      ),
      body: cartState.isLoading
          ? _buildLoadingIndicator()
          : (cartItems.isEmpty 
            ? _buildEmptyCart() 
            : _buildCartContent(context, cartItems, cartState.totalPrice, ref)),
      bottomNavigationBar: cartItems.isEmpty 
          ? null 
          : _buildBottomBar(context, cartState.totalPrice),
    );
  }

  Widget _buildEmptyCart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icône de panier vide et cercle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 24),
        // Message principal
        const Text(
          'Votre panier est vide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Message secondaire
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Ajoutez des produits pour commencer vos achats',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Bouton pour commencer les achats
        ElevatedButton.icon(
          onPressed: () {
            // Naviguer vers l'écran d'accueil ou le scanner
            final navNotifier = ref.read(selectedNavIndexProvider.notifier);
            navNotifier.state = 0; // Aller à l'écran d'accueil
          },
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Commencer vos achats'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCartContent(BuildContext context, List<CartItem> items, double totalPrice, WidgetRef ref) {
    return SafeArea(
      // Utiliser SafeArea pour éviter les débordements avec l'interface système
      bottom: false, // La barre inférieure gère déjà l'espace
      child: Column(
        children: [
          // En-tête avec le nombre d'articles
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Text(
                  '${items.length} article${items.length > 1 ? 's' : ''} dans votre panier',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Ligne de séparation
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          
          // Liste des articles avec Expanded pour éviter les débordements
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildCartItemCard(context, item, ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1, // Réduire l'élévation pour un style plus moderne
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Première ligne : image, nom et bouton de suppression
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du produit
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: item.product.imageUrl.isNotEmpty
                      ? Image.network(
                          item.product.imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                ),
                
                const SizedBox(width: 12),
                
                // Détails du produit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.product.brand,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Prix unitaire et prix total
                      Row(
                        children: [
                          Text(
                            '${item.product.price.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '× ${item.quantity}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Bouton de suppression
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showRemoveItemDialog(context, ref, item),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Deuxième ligne : contrôles de quantité
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Quantité:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                
                // Bouton de réduction
                _buildQuantityButton(
                  icon: Icons.remove,
                  color: Colors.red.shade200,
                  onTap: () {
                    final newQuantity = item.quantity - 1;
                    if (newQuantity >= 1) {
                      ref.read(cartProvider.notifier).updateQuantity(
                        item.product, 
                        newQuantity
                      );
                    } else {
                      _showRemoveItemDialog(context, ref, item);
                    }
                  },
                ),
                
                // Affichage de la quantité
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Bouton d'augmentation
                _buildQuantityButton(
                  icon: Icons.add,
                  color: Colors.green.shade300,
                  onTap: () {
                    if (item.quantity < item.product.quantity) {
                      ref.read(cartProvider.notifier).updateQuantity(
                        item.product, 
                        item.quantity + 1
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Impossible d\'ajouter plus de ${item.product.name}. Stock disponible: ${item.product.quantity}'
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour les boutons de quantité pour éviter la duplication
  Widget _buildQuantityButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, double totalPrice) {
    // Utiliser une approche plus simple avec une hauteur fixe
    return Container(
      height: 88, // Hauteur fixe suffisante
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Prix total - Colonne avec hauteur contrainte
            Container(
              width: 100, // Largeur fixe pour le prix
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Espace flexible entre le prix et le bouton
            const Spacer(),
            
            // Bouton de paiement - Taille fixe pour éviter les débordements
            ElevatedButton(
              onPressed: () {
                // TODO: Implémenter le processus de paiement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité de paiement à implémenter'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                minimumSize: const Size(120, 48), // Taille minimale pour assurer la visibilité
              ),
              child: const Text(
                'Payer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // S'assurer que le texte est blanc
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du panier...'),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, WidgetRef ref, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text('Voulez-vous retirer "${item.product.name}" de votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeFromCart(item.product);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.product.name} retiré du panier'),
                ),
              );
            },
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Panier vidé'),
                ),
              );
            },
            child: const Text('Vider'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
} 
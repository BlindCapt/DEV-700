import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';

// Provider pour l'index de navigation sélectionné
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

class MainBottomNavBar extends ConsumerWidget {
  final Function(int) onItemSelected;

  const MainBottomNavBar({
    Key? key,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final cartState = ref.watch(cartProvider);
    final cartItemCount = cartState.items.length;

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        // Si l'utilisateur clique sur l'onglet Panier, rafraîchir le panier
        if (index == 2) { // L'index 2 correspond à l'onglet Panier
          debugPrint('Onglet Panier sélectionné, rafraîchissement automatique');
          ref.read(cartProvider.notifier).refreshCart();
        }
        
        ref.read(selectedNavIndexProvider.notifier).state = index;
        onItemSelected(index);
      },
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart),
              if (cartItemCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Panier',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../scanner/presentation/screens/barcode_scanner_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    
    // Liste des écrans à afficher en fonction de l'index sélectionné
    final List<Widget> screens = [
      const HomeScreen(),
      const BarcodeScannerScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: MainBottomNavBar(
        onItemSelected: (index) {
          // La navigation est gérée par le provider et le IndexedStack
        },
      ),
    );
  }
} 
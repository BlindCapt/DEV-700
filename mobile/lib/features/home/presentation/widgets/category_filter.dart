import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  // Définition des styles constants
  static const TextStyle _selectedTextStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.3,
    shadows: null,
  );
  
  static const TextStyle _unselectedTextStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 0.3,
    shadows: null,
  );

  const CategoryFilter({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'Parcourir par catégorie',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length + 1, // +1 pour "Tous"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Premier élément : "Tous"
                  return _buildCategoryItem(
                    context, 
                    null, 
                    'Tous', 
                    Icons.apps_rounded,
                    selectedCategory == null,
                  );
                } else {
                  // Autres catégories
                  final category = categories[index - 1];
                  return _buildCategoryItem(
                    context, 
                    category, 
                    category, 
                    _getCategoryIcon(category),
                    selectedCategory == category,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(
    BuildContext context, 
    String? category, 
    String label, 
    IconData icon,
    bool isSelected,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return GestureDetector(
      onTap: () => onCategorySelected(category),
      child: Container(
        width: 75,
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.grey[800] : primaryColor,
                border: Border.all(
                  color: isSelected ? Colors.grey[600]! : primaryColor,
                  width: isSelected ? 1 : 2,
                ),
                boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      )
                    ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: isSelected ? _selectedTextStyle : _unselectedTextStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    // Icônes améliorées pour les catégories courantes
    if (categoryLower.contains('électronique')) return Icons.devices_other;
    if (categoryLower.contains('ordinateur') || categoryLower.contains('pc')) return Icons.laptop;
    if (categoryLower.contains('téléphone') || categoryLower.contains('mobile')) return Icons.phone_android;
    if (categoryLower.contains('alimentaire') || categoryLower.contains('nourriture')) return Icons.fastfood;
    
    // Icônes spécifiques pour beverage et snack
    if (categoryLower == 'beverage' || categoryLower.contains('boisson')) return Icons.emoji_food_beverage;
    if (categoryLower == 'snack' || categoryLower.contains('gâteau') || categoryLower.contains('gateau')) return Icons.bakery_dining;
    
    if (categoryLower.contains('fruit')) return Icons.apple;
    if (categoryLower.contains('légume')) return Icons.local_florist;
    if (categoryLower.contains('viande')) return Icons.set_meal;
    if (categoryLower.contains('dessert') || categoryLower.contains('sucré')) return Icons.icecream;
    if (categoryLower.contains('vêtement') || categoryLower.contains('mode')) return Icons.shopping_bag;
    if (categoryLower.contains('chaussure')) return Icons.gesture_outlined;
    if (categoryLower.contains('accessoire')) return Icons.watch;
    if (categoryLower.contains('sac') || categoryLower.contains('bagage')) return Icons.luggage;
    if (categoryLower.contains('hygiene') || categoryLower.contains('beauté')) return Icons.spa;
    if (categoryLower.contains('sport')) return Icons.sports;
    if (categoryLower.contains('football') || categoryLower.contains('ballon')) return Icons.sports_soccer;
    if (categoryLower.contains('tennis')) return Icons.sports_tennis;
    if (categoryLower.contains('basketball')) return Icons.sports_basketball;
    if (categoryLower.contains('maison')) return Icons.home_filled;
    if (categoryLower.contains('meuble')) return Icons.weekend;
    if (categoryLower.contains('cuisine')) return Icons.kitchen;
    if (categoryLower.contains('jardin')) return Icons.grass;
    if (categoryLower.contains('outil')) return Icons.handyman;
    if (categoryLower.contains('brico')) return Icons.construction;
    if (categoryLower.contains('livre')) return Icons.auto_stories;
    if (categoryLower.contains('média') || categoryLower.contains('dvd')) return Icons.movie;
    if (categoryLower.contains('musique')) return Icons.headphones;
    if (categoryLower.contains('jouet')) return Icons.toys;
    if (categoryLower.contains('bébé') || categoryLower.contains('enfant')) return Icons.child_friendly;
    if (categoryLower.contains('santé')) return Icons.health_and_safety;
    if (categoryLower.contains('auto') || categoryLower.contains('voiture')) return Icons.electric_car;
    
    // Icône par défaut si aucune correspondance
    return Icons.category;
  }
} 
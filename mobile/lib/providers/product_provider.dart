import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/products/data/api/product_api_service.dart';
import '../features/products/domain/models/product.dart';
import 'auth_provider.dart';

// État pour gérer les produits
class ProductState {
  final bool isLoading;
  final String? error;
  final List<Product> products;
  final Product? selectedProduct;
  final List<String> categories;
  
  ProductState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.selectedProduct,
    this.categories = const [],
  });
  
  ProductState copyWith({
    bool? isLoading,
    String? error,
    List<Product>? products,
    Product? selectedProduct,
    List<String>? categories,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      categories: categories ?? this.categories,
    );
  }
}

// Provider pour le service de produits
final productApiServiceProvider = Provider<ProductApiService>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  return ProductApiService(authService);
});

// Notifier pour gérer l'état des produits
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductApiService _productService;
  
  ProductNotifier(this._productService) : super(ProductState());
  
  // Méthode pour scanner un produit par code-barres
  Future<Product?> scanProduct(String barcode) async {
    debugPrint('Scan de produit avec code-barres: $barcode');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final product = await _productService.getProductByBarcode(barcode);
      
      if (product != null) {
        state = state.copyWith(
          isLoading: false,
          selectedProduct: product,
        );
        return product;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Ce produit n\'est pas disponible à la vente dans notre magasin.',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors du scan: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du scan: $e',
      );
      return null;
    }
  }
  
  // Méthode pour récupérer tous les produits
  Future<void> fetchAllProducts() async {
    debugPrint('Récupération de tous les produits');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final products = await _productService.getAllProducts();
      
      // Extraire les catégories uniques
      final Set<String> categoriesSet = {};
      for (var product in products) {
        if (product.category.isNotEmpty) {
          categoriesSet.add(product.category);
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        products: products,
        categories: categoriesSet.toList()..sort(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération des produits: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la récupération des produits: $e',
      );
    }
  }
}

// Provider pour l'état des produits
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final productService = ref.watch(productApiServiceProvider);
  return ProductNotifier(productService);
}); 
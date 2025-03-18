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
  
  ProductState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.selectedProduct,
  });
  
  ProductState copyWith({
    bool? isLoading,
    String? error,
    List<Product>? products,
    Product? selectedProduct,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
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
          error: 'Aucun produit trouvé avec ce code-barres',
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
}

// Provider pour l'état des produits
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final productService = ref.watch(productApiServiceProvider);
  return ProductNotifier(productService);
}); 
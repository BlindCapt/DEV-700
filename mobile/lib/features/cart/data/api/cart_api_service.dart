import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/api_url_resolver.dart';
import '../../../../core/utils/token_manager.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/models/cart_item.dart';

class CartApiService {
  final ApiUrlResolver _apiUrlResolver = ApiUrlResolver();
  final TokenManager _tokenManager = TokenManager();

  // Récupérer le panier actif de l'utilisateur
  Future<List<CartItem>> fetchCart() async {
    try {
      // Vérifier d'abord si l'utilisateur est authentifié
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible de récupérer le panier');
        return [];
      }
      
      final url = await _apiUrlResolver.getApiUrl();
      debugPrint('Récupération du panier depuis: $url/api/carts/active');

      final response = await http.get(
        Uri.parse('$url/api/carts/active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Panier récupéré avec succès');
        final data = jsonDecode(response.body);
        
        // Plus de détails de débogage sur la structure de la réponse
        debugPrint('Structure de la réponse: ${data.keys.join(', ')}');
        
        // Vérifier si la réponse contient "cartItems" ou "items" pour être flexible
        final List<dynamic> cartItems;
        if (data.containsKey('cartItems')) {
          cartItems = data['cartItems'];
          debugPrint('Utilisation de la clé "cartItems" dans la réponse');
        } else if (data.containsKey('items')) {
          cartItems = data['items'];
          debugPrint('Utilisation de la clé "items" dans la réponse');
        } else {
          // Si la structure est inattendue, essayer de détecter un tableau d'éléments
          debugPrint('Structure de réponse inattendue, recherche d\'alternatives');
          
          if (data is Map && data.containsKey('id')) {
            // Cas où le panier est directement renvoyé
            if (data.containsKey('items') && data['items'] is List) {
              cartItems = data['items'];
              debugPrint('Panier trouvé avec la clé "items" à la racine');
            } else if (data.containsKey('Items') && data['Items'] is List) {
              cartItems = data['Items'];
              debugPrint('Panier trouvé avec la clé "Items" à la racine');
            } else {
              debugPrint('Panier trouvé mais structure des items inconnue: ${response.body}');
              return [];
            }
          } else {
            debugPrint('Structure de réponse non reconnue: ${response.body}');
            return [];
          }
        }
        
        debugPrint('Nombre d\'articles dans le panier: ${cartItems.length}');
        debugPrint('Premier article structure: ${cartItems.isNotEmpty ? cartItems.first.keys.join(', ') : 'aucun article'}');
        
        final items = cartItems.map((item) {
          try {
            // Vérifier la structure de l'élément
            if (!item.containsKey('product')) {
              debugPrint('Article sans clé "product": $item');
              return null;
            }
            
            final product = item['product'];
            
            return CartItem(
              product: Product(
                id: product['id'],
                barcode: product['barcode'],
                name: product['name'],
                brand: product['brand'],
                category: product['category'],
                imageUrl: product['imageUrl'] ?? '',
                price: product['price'].toDouble(),
                quantity: product['quantity'],
                threshold: product['threshold'],
                description: product['description'] ?? '',
              ),
              quantity: item['quantity'],
            );
          } catch (e) {
            debugPrint('Erreur lors de la conversion d\'un article: $e');
            return null;
          }
        }).where((item) => item != null).cast<CartItem>().toList();
        
        return items;
      } else if (response.statusCode == 404) {
        // Aucun panier actif trouvé, ce n'est pas une erreur
        debugPrint('Aucun panier actif trouvé (404)');
        return [];
      } else if (response.statusCode == 401) {
        // Token invalide, enregistrer l'erreur
        debugPrint('Token non valide ou expiré (401)');
        // Nettoyer le token
        await _tokenManager.clearTokens();
        return [];
      } else {
        debugPrint('Erreur HTTP ${response.statusCode} lors de la récupération du panier: ${response.body}');
        return [];
      }
    } on FormatException catch (e) {
      debugPrint('Erreur de format JSON lors de la récupération du panier: $e');
      return [];
    } on TimeoutException catch (e) {
      debugPrint('Timeout lors de la récupération du panier: $e');
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération du panier: $e');
      return [];
    }
  }

  // Créer un nouveau panier
  Future<bool> createCart() async {
    debugPrint('==== DÉBUT createCart() ====');
    try {
      // Vérifier d'abord si l'utilisateur est authentifié
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible de créer un panier');
        return false;
      }
      
      // Afficher la longueur du token pour débogage
      debugPrint('Token disponible pour créer un panier (longueur: ${token.length})');
      
      final url = await _apiUrlResolver.getApiUrl();
      debugPrint('Création d\'un nouveau panier à: $url/api/carts');

      // Ajout d'un timeout plus long pour les réseaux lents
      final response = await http.post(
        Uri.parse('$url/api/carts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));  // Augmenter le timeout à 15 secondes

      final success = response.statusCode == 201 || response.statusCode == 200;
      
      if (success) {
        debugPrint('Panier créé avec succès: ${response.body}');
      } else if (response.statusCode == 401) {
        debugPrint('Token non valide lors de la création du panier: HTTP 401');
        // Nettoyer le token invalide
        await _tokenManager.clearTokens();
      } else {
        debugPrint('Échec de la création du panier: HTTP ${response.statusCode}, ${response.body}');
      }
      
      debugPrint('==== FIN createCart(): ${success ? "Succès" : "Échec"} ====');
      return success;
    } on TimeoutException catch (e) {
      debugPrint('Timeout lors de la création du panier: $e');
      debugPrint('==== FIN createCart(): Timeout ====');
      return false; 
    } catch (e) {
      debugPrint('Erreur lors de la création du panier: $e');
      debugPrint('==== FIN createCart(): Erreur ====');
      return false;
    }
  }

  // Ajouter un produit au panier
  Future<bool> addToCart(int productId, int quantity) async {
    try {
      final url = await _apiUrlResolver.getApiUrl();
      final token = await _tokenManager.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$url/api/carts/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au panier: $e');
      return false;
    }
  }

  // Mettre à jour la quantité d'un produit dans le panier
  Future<bool> updateCartItem(int productId, int quantity) async {
    try {
      final url = await _apiUrlResolver.getApiUrl();
      final token = await _tokenManager.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.put(
        Uri.parse('$url/api/carts/items/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du panier: $e');
      return false;
    }
  }

  // Supprimer un produit du panier
  Future<bool> removeFromCart(int productId) async {
    try {
      final url = await _apiUrlResolver.getApiUrl();
      final token = await _tokenManager.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$url/api/carts/items/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du panier: $e');
      return false;
    }
  }

  // Vider le panier
  Future<bool> clearCart() async {
    try {
      final url = await _apiUrlResolver.getApiUrl();
      final token = await _tokenManager.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$url/api/carts/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors du vidage du panier: $e');
      return false;
    }
  }
} 
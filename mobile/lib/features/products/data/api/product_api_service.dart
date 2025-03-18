import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/product.dart';
import '../../../../../features/auth/data/api/auth_api_service.dart';

class ProductApiService {
  final AuthApiService _authService;

  ProductApiService(this._authService);

  // Récupérer un produit par son code-barres
  Future<Product?> getProductByBarcode(String barcode) async {
    debugPrint('Récupération du produit avec le code-barres: $barcode');
    
    try {
      // Test ping pour établir la connexion si nécessaire
      await _authService.testPing();
      
      // Construire l'URL de l'endpoint
      final url = '${_authService.currentApiUrl}/api/products/barcode/$barcode';
      debugPrint('Appel API: $url');
      
      // Récupérer le token d'authentification
      final token = await _authService.getToken();
      
      // Préparer les en-têtes de la requête
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      // Envoyer la requête
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      // Traiter la réponse
      if (response.statusCode == 200) {
        debugPrint('Produit trouvé: ${response.body}');
        final data = json.decode(response.body);
        return Product.fromJson(data);
      } else {
        debugPrint('Aucun produit trouvé: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du produit: $e');
      return null;
    }
  }
} 
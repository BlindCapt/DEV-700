import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_url_resolver.dart';
import '../../../core/utils/token_manager.dart';

class InvoiceService {
  final ApiUrlResolver _apiUrlResolver = ApiUrlResolver();
  final TokenManager _tokenManager = TokenManager();
  
  // Durée de timeout des requêtes HTTP
  static const Duration _timeout = Duration(seconds: 10);
  
  // URL de l'API mise en cache
  String? _cachedApiUrl;

  // Récupérer l'URL de l'API avec mise en cache
  Future<String> _getApiUrl() async {
    if (_cachedApiUrl == null) {
      _cachedApiUrl = await _apiUrlResolver.getApiUrl();
    }
    return _cachedApiUrl!;
  }

  // Créer une facture à partir d'un panier
  Future<Map<String, dynamic>?> createInvoice(int cartId, String? billingAddress) async {
    try {
      // Vérifier d'abord si l'utilisateur est authentifié
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible de créer une facture');
        return null;
      }
      
      final url = await _getApiUrl();
      debugPrint('Création d\'une facture pour le panier $cartId à $url/api/mobile/invoices/cart/$cartId');
      debugPrint('Token utilisé (tronqué): ${token.substring(0, 20)}...');
      
      // Analyse du JWT token pour débuggage
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          // Décoder le payload (deuxième partie du token)
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decodedPayload = utf8.decode(base64Url.decode(normalized));
          debugPrint('Payload du token JWT: $decodedPayload');
          
          // Vérifier si le claim NameIdentifier est présent
          final payloadJson = jsonDecode(decodedPayload);
          final nameIdentifierClaim = payloadJson['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
          final userType = payloadJson['UserType'];
          
          debugPrint('Claim NameIdentifier: $nameIdentifierClaim');
          debugPrint('Claim UserType: $userType');
          
          if (nameIdentifierClaim == null) {
            debugPrint('ALERTE: Le claim NameIdentifier est manquant dans le token!');
          }
          
          if (userType != 'MobileUser') {
            debugPrint('ALERTE: Le UserType n\'est pas "MobileUser" mais "$userType"!');
          }
        } else {
          debugPrint('Format de token invalide: ${parts.length} parties au lieu de 3');
        }
      } catch (e) {
        debugPrint('Erreur lors de l\'analyse du token: $e');
      }

      // Tester d'abord la validité du token avec un endpoint simple
      try {
        final testResponse = await http.get(
          Uri.parse('$url/api/mobile/user/validate'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(_timeout);
        
        debugPrint('Test de validité du token: ${testResponse.statusCode}');
        debugPrint('Réponse du test: ${testResponse.body}');
        
        if (testResponse.statusCode != 200) {
          debugPrint('ALERTE: Le token n\'est pas valide selon l\'endpoint de validation!');
        }
      } catch (e) {
        debugPrint('Erreur lors du test de validité du token: $e');
      }

      final response = await http.post(
        Uri.parse('$url/api/mobile/invoices/cart/$cartId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(billingAddress ?? ''),
      ).timeout(_timeout);

      debugPrint('Réponse reçue: Code ${response.statusCode}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Facture créée avec succès');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        debugPrint('Token non valide lors de la création de la facture: HTTP 401');
        debugPrint('Détails de l\'erreur: ${response.body}');
        
        // Récupérer les en-têtes de la réponse pour plus d'informations
        debugPrint('En-têtes de la réponse: ${response.headers}');
        
        // Attendre un peu et essayer de créer un nouveau token
        await Future.delayed(Duration(seconds: 1));
        await _tokenManager.clearTokens();
        return null;
      } else {
        debugPrint('Échec de la création de la facture: HTTP ${response.statusCode}, ${response.body}');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout lors de la création de la facture: $e');
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la création de la facture: $e');
      return null;
    }
  }

  // Mettre à jour le statut d'une facture à "Paid"
  Future<bool> payInvoice(int invoiceId, String? paymentMethod) async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible de payer la facture');
        return false;
      }
      
      final url = await _getApiUrl();
      debugPrint('Paiement de la facture $invoiceId à $url/api/mobile/invoices/$invoiceId/pay');

      final response = await http.post(
        Uri.parse('$url/api/mobile/invoices/$invoiceId/pay'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentMethod': paymentMethod ?? 'cash',
          'paymentReference': 'mobile-payment-${DateTime.now().millisecondsSinceEpoch}',
        }),
      ).timeout(_timeout);

      // Considérer 200 et 204 comme des succès
      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        debugPrint('Facture payée avec succès (code: ${response.statusCode})');
      } else {
        debugPrint('Échec du paiement de la facture: HTTP ${response.statusCode}, ${response.body}');
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors du paiement de la facture: $e');
      return false;
    }
  }

  // Annuler une facture
  Future<bool> cancelInvoice(int invoiceId) async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible d\'annuler la facture');
        return false;
      }
      
      final url = await _getApiUrl();
      debugPrint('Annulation de la facture $invoiceId à $url/api/mobile/invoices/$invoiceId/cancel');

      final response = await http.post(
        Uri.parse('$url/api/mobile/invoices/$invoiceId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      // Considérer 200 et 204 comme des succès
      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        debugPrint('Facture annulée avec succès (code: ${response.statusCode})');
      } else {
        debugPrint('Échec de l\'annulation de la facture: HTTP ${response.statusCode}, ${response.body}');
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de l\'annulation de la facture: $e');
      return false;
    }
  }
}

// Provider pour le service des factures
final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService();
}); 
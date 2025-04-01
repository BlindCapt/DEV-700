import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/api_url_resolver.dart';
import '../../../core/utils/token_manager.dart';
import '../models/order_history.dart';

class OrderHistoryService {
  final ApiUrlResolver _apiUrlResolver = ApiUrlResolver();
  final TokenManager _tokenManager = TokenManager();
  
  // Durée de timeout des requêtes HTTP
  static const Duration _timeout = Duration(seconds: 15);
  
  // URL de l'API mise en cache
  String? _cachedApiUrl;

  // Récupérer l'URL de l'API avec mise en cache
  Future<String> _getApiUrl() async {
    if (_cachedApiUrl == null) {
      _cachedApiUrl = await _apiUrlResolver.getApiUrl();
    }
    return _cachedApiUrl!;
  }

  // Récupérer toutes les factures de l'utilisateur courant
  Future<List<Invoice>> getUserInvoices() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible de récupérer les factures');
        return [];
      }
      
      final url = await _getApiUrl();
      debugPrint('Récupération des factures à $url/api/mobile/invoices');
      
      final response = await http.get(
        Uri.parse('$url/api/mobile/invoices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('Réponse reçue: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Invoice.fromJson(json)).toList();
      } else {
        debugPrint('Échec de la récupération des factures: HTTP ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des factures: $e');
      return [];
    }
  }

  // Récupérer les détails d'une facture
  Future<Invoice?> getInvoiceDetails(int invoiceId) async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) {
        debugPrint('Utilisateur non authentifié, impossible de récupérer les détails de la facture');
        return null;
      }
      
      final url = await _getApiUrl();
      debugPrint('Récupération des détails de la facture $invoiceId à $url/api/mobile/invoices/$invoiceId');
      
      final response = await http.get(
        Uri.parse('$url/api/mobile/invoices/$invoiceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('Réponse détaillée reçue: ${response.body}');
        final dynamic data = jsonDecode(response.body);
        final Invoice invoice = Invoice.fromJson(data);
        
        // Si le panier n'a pas d'articles, essayons de les récupérer séparément
        if (invoice.cart == null || invoice.cart!.items.isEmpty) {
          debugPrint('Le panier de la facture est vide, tentative de récupération séparée des articles');
          
          // Vérifier si on peut récupérer les détails du panier
          if (invoice.cartId > 0) {
            try {
              final cartResponse = await http.get(
                Uri.parse('$url/api/carts/${invoice.cartId}'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              ).timeout(_timeout);
              
              if (cartResponse.statusCode == 200) {
                debugPrint('Détails du panier récupérés séparément: ${cartResponse.body}');
                final cartData = jsonDecode(cartResponse.body);
                
                // Créer une nouvelle facture avec les données du panier
                return Invoice(
                  id: invoice.id,
                  invoiceNumber: invoice.invoiceNumber,
                  mobileUserId: invoice.mobileUserId,
                  cartId: invoice.cartId,
                  createdAt: invoice.createdAt,
                  paidAt: invoice.paidAt,
                  totalAmount: invoice.totalAmount,
                  status: invoice.status,
                  paymentMethod: invoice.paymentMethod,
                  paymentReference: invoice.paymentReference,
                  billingAddress: invoice.billingAddress,
                  notes: invoice.notes,
                  cart: Cart.fromJson(cartData),
                );
              }
            } catch (e) {
              debugPrint('Erreur lors de la récupération séparée du panier: $e');
            }
          }
        }
        
        return invoice;
      } else {
        debugPrint('Échec de la récupération des détails de la facture: HTTP ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails de la facture: $e');
      return null;
    }
  }
  
  // Demander un remboursement (à implémenter plus tard)
  Future<bool> requestRefund(int invoiceId) async {
    // Cette méthode ne fait rien pour le moment, mais elle est prête à être implémentée plus tard
    debugPrint('Demande de remboursement pour la facture $invoiceId (fonctionnalité à implémenter)');
    return true;
  }
}

// Provider pour le service d'historique des commandes
final orderHistoryServiceProvider = Provider<OrderHistoryService>((ref) {
  return OrderHistoryService();
}); 
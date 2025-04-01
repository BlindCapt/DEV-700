import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../features/payment/services/invoice_service.dart';
import '../features/cart/data/api/cart_api_service.dart';
import 'cart_provider.dart';

enum InvoiceStatus {
  pending,
  paid,
  cancelled,
  refunded,
  unknown
}

class InvoiceState {
  final int? invoiceId;
  final String? invoiceNumber;
  final InvoiceStatus status;
  final double totalAmount;
  final bool isProcessing;
  final String? error;
  
  InvoiceState({
    this.invoiceId,
    this.invoiceNumber,
    this.status = InvoiceStatus.unknown,
    this.totalAmount = 0.0,
    this.isProcessing = false,
    this.error,
  });
  
  InvoiceState copyWith({
    int? invoiceId,
    String? invoiceNumber,
    InvoiceStatus? status,
    double? totalAmount,
    bool? isProcessing,
    String? error,
  }) {
    return InvoiceState(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
  
  static InvoiceStatus parseStatus(String? statusStr) {
    if (statusStr == null) return InvoiceStatus.unknown;
    
    switch (statusStr.toLowerCase()) {
      case 'pending': return InvoiceStatus.pending;
      case 'paid': return InvoiceStatus.paid;
      case 'cancelled': return InvoiceStatus.cancelled;
      case 'refunded': return InvoiceStatus.refunded;
      default: return InvoiceStatus.unknown;
    }
  }
}

class InvoiceNotifier extends StateNotifier<InvoiceState> {
  final InvoiceService _invoiceService;
  final Ref _ref;
  
  InvoiceNotifier(this._ref)
      : _invoiceService = _ref.read(invoiceServiceProvider),
        super(InvoiceState());
  
  // Créer une facture à partir du panier actif
  Future<bool> createInvoice({String? billingAddress}) async {
    try {
      state = state.copyWith(isProcessing: true, error: null);
      
      // Récupérer l'état actuel du panier
      final cartState = _ref.read(cartProvider);
      if (cartState.items.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Le panier est vide'
        );
        return false;
      }
      
      // Supposer que le panier a un ID (qui devrait être disponible via une API)
      // Dans une application réelle, vous pourriez avoir besoin d'accéder à cet ID depuis l'état du panier
      final cartId = await _getCartId();
      if (cartId == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Impossible de déterminer l\'ID du panier'
        );
        return false;
      }
      
      // Appeler le service pour créer la facture
      final invoiceData = await _invoiceService.createInvoice(cartId, billingAddress);
      if (invoiceData == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Échec de la création de la facture'
        );
        return false;
      }
      
      // Mettre à jour l'état avec les données de la facture
      state = state.copyWith(
        invoiceId: invoiceData['id'],
        invoiceNumber: invoiceData['invoiceNumber'],
        status: InvoiceState.parseStatus(invoiceData['status']),
        totalAmount: invoiceData['totalAmount']?.toDouble() ?? cartState.totalPrice,
        isProcessing: false
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la création de la facture: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Erreur: $e'
      );
      return false;
    }
  }
  
  // Payer la facture
  Future<bool> payInvoice({String? paymentMethod}) async {
    try {
      if (state.invoiceId == null) {
        state = state.copyWith(error: 'Aucune facture active');
        return false;
      }
      
      state = state.copyWith(isProcessing: true, error: null);
      
      final success = await _invoiceService.payInvoice(state.invoiceId!, paymentMethod);
      if (success) {
        state = state.copyWith(
          status: InvoiceStatus.paid,
          isProcessing: false
        );
        
        // Rafraîchir le panier car il devrait maintenant être désactivé
        _ref.read(cartProvider.notifier).refreshCart();
        
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: 'Échec du paiement de la facture'
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Erreur: $e'
      );
      return false;
    }
  }
  
  // Annuler la facture
  Future<bool> cancelInvoice() async {
    try {
      if (state.invoiceId == null) {
        state = state.copyWith(error: 'Aucune facture active');
        return false;
      }
      
      state = state.copyWith(isProcessing: true, error: null);
      
      final success = await _invoiceService.cancelInvoice(state.invoiceId!);
      if (success) {
        state = state.copyWith(
          status: InvoiceStatus.cancelled,
          isProcessing: false
        );
        
        // Rafraîchir le panier
        _ref.read(cartProvider.notifier).refreshCart();
        
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: 'Échec de l\'annulation de la facture'
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Erreur: $e'
      );
      return false;
    }
  }
  
  // Réinitialiser l'état de la facture
  void resetInvoiceState() {
    state = InvoiceState();
  }
  
  // Obtenir l'ID du panier actif depuis l'API
  Future<int?> _getCartId() async {
    try {
      // Utiliser le CartApiService pour récupérer l'ID du panier actif
      final cartApiService = CartApiService();
      final cartId = await cartApiService.getActiveCartId();
      
      if (cartId == null) {
        debugPrint('Aucun ID de panier actif trouvé');
      } else {
        debugPrint('ID du panier actif récupéré: $cartId');
      }
      
      return cartId;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'ID du panier: $e');
      return null;
    }
  }
}

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  return InvoiceNotifier(ref);
}); 
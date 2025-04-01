import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_history.dart';
import '../services/order_history_service.dart';

// État pour l'historique des commandes
class OrderHistoryState {
  final List<Invoice> invoices;
  final bool isLoading;
  final String? error;
  final Invoice? selectedInvoice;

  OrderHistoryState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
    this.selectedInvoice,
  });

  OrderHistoryState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? error,
    Invoice? selectedInvoice,
    bool clearError = false,
    bool clearSelectedInvoice = false,
  }) {
    return OrderHistoryState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      selectedInvoice: clearSelectedInvoice ? null : selectedInvoice ?? this.selectedInvoice,
    );
  }
}

// Notifier pour l'historique des commandes
class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  final OrderHistoryService _service;

  OrderHistoryNotifier(this._service) : super(OrderHistoryState());

  // Charger toutes les factures de l'utilisateur
  Future<void> loadUserInvoices() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final invoices = await _service.getUserInvoices();
      state = state.copyWith(
        invoices: invoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des factures: $e',
      );
    }
  }

  // Charger les détails d'une facture
  Future<void> loadInvoiceDetails(int invoiceId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final invoice = await _service.getInvoiceDetails(invoiceId);
      
      if (invoice != null) {
        state = state.copyWith(
          selectedInvoice: invoice,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible de charger les détails de la facture',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des détails de la facture: $e',
      );
    }
  }

  // Demander un remboursement
  Future<void> requestRefund(int invoiceId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final success = await _service.requestRefund(invoiceId);
      
      if (success) {
        // Recharger les factures après la demande de remboursement
        await loadUserInvoices();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Échec de la demande de remboursement',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la demande de remboursement: $e',
      );
    }
  }

  // Effacer la facture sélectionnée
  void clearSelectedInvoice() {
    state = state.copyWith(clearSelectedInvoice: true);
  }
}

// Provider pour l'état de l'historique des commandes
final orderHistoryProvider = StateNotifierProvider<OrderHistoryNotifier, OrderHistoryState>((ref) {
  final service = ref.watch(orderHistoryServiceProvider);
  return OrderHistoryNotifier(service);
}); 
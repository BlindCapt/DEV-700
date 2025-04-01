import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/order_history_provider.dart';
import '../../models/order_history.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final int invoiceId;

  const OrderDetailsScreen({
    Key? key,
    required this.invoiceId,
  }) : super(key: key);

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les détails de la facture lorsque l'écran est initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).loadInvoiceDetails(widget.invoiceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderHistoryProvider);
    final invoice = state.selectedInvoice;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la commande'),
        actions: [
          // Bouton de rafraîchissement pour recharger les détails
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(orderHistoryProvider.notifier).loadInvoiceDetails(widget.invoiceId);
            },
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(state, invoice),
      bottomNavigationBar: invoice != null && invoice.status == InvoiceStatus.paid
          ? _buildRefundButton(invoice)
          : null,
    );
  }

  Widget _buildBody(OrderHistoryState state, Invoice? invoice) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(orderHistoryProvider.notifier).loadInvoiceDetails(widget.invoiceId);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (invoice == null) {
      return const Center(
        child: Text('Aucune information disponible pour cette commande'),
      );
    }

    // Afficher les détails bruts pour debug
    debugPrint("Contenu de l'invoice: id=${invoice.id}, cart=${invoice.cart != null}, items=${invoice.cart?.items.length ?? 0}");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(invoice),
          const SizedBox(height: 24),
          _buildStatusInfo(invoice),
          const SizedBox(height: 24),
          _buildBillingInfo(invoice),
          const SizedBox(height: 24),
          _buildItemsList(invoice),
          const SizedBox(height: 24),
          _buildTotalSection(invoice),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(Invoice invoice) {
    // Formater la date de création
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = dateFormat.format(invoice.createdAt);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commande #${invoice.invoiceNumber}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Date: $createdAt',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(Invoice invoice) {
    // Définir la couleur selon le statut
    Color statusColor;
    String statusText;
    
    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusColor = Colors.green;
        statusText = 'Payée';
        break;
      case InvoiceStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Annulée';
        break;
      case InvoiceStatus.refunded:
        statusColor = Colors.orange;
        statusText = 'Remboursée';
        break;
      case InvoiceStatus.pending:
      default:
        statusColor = Colors.blue;
        statusText = 'En attente';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(invoice.status),
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (invoice.paidAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Payée le: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.paidAt!)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      case InvoiceStatus.refunded:
        return Icons.currency_exchange;
      case InvoiceStatus.pending:
      default:
        return Icons.pending;
    }
  }

  Widget _buildBillingInfo(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse de facturation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            invoice.billingAddress ?? 'Non spécifiée',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(Invoice invoice) {
    // Vérifier si les informations du panier sont disponibles
    if (invoice.cart == null || invoice.cart!.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Articles commandés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Impossible d\'afficher le détail des articles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le détail des articles n\'est pas disponible pour cette commande.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(orderHistoryProvider.notifier).loadInvoiceDetails(widget.invoiceId);
                    },
                    child: const Text('Rafraîchir'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Articles commandés',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoice.cart!.items.length,
          itemBuilder: (context, index) {
            final item = invoice.cart!.items[index];
            return _buildCartItemCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final price = currencyFormat.format(item.product.price);
    final total = currencyFormat.format(item.product.price * item.quantity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image du produit
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: item.product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported, color: Colors.grey.shade600);
                        },
                      ),
                    )
                  : Icon(Icons.shopping_bag, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            // Informations sur le produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.product.brand.isNotEmpty)
                    Text(
                      item.product.brand,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$price x ${item.quantity}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        total,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(Invoice invoice) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final totalAmount = currencyFormat.format(invoice.totalAmount);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Montant total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            totalAmount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundButton(Invoice invoice) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            _showRefundConfirmationDialog(invoice);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Demander un remboursement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRefundConfirmationDialog(Invoice invoice) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande de remboursement'),
        content: const Text(
          'Êtes-vous sûr de vouloir demander un remboursement pour cette commande? '
          'Cette fonctionnalité n\'est pas encore implémentée et sera disponible dans une future mise à jour.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La demande de remboursement sera bientôt disponible.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
} 
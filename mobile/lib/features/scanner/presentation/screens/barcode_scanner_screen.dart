import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../providers/product_provider.dart';
import '../../../products/domain/models/product.dart';
import '../../../../providers/cart_provider.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  String _scannedBarcode = 'Aucun code scanné';
  bool _isLoading = false;
  bool _isScanning = false;
  Product? _scannedProduct;
  String? _errorMessage;
  late TextEditingController _barcodeController;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de code-barres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card pour le scan
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Code-barres: $_scannedBarcode',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Ajout du champ de saisie manuelle
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Saisir un code-barres manuellement',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () => _processManualBarcode(context),
                            tooltip: 'Rechercher',
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _barcodeController,
                        onSubmitted: (_) => _processManualBarcode(context),
                      ),
                      
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleScanner,
                        icon: Icon(_isScanning ? Icons.stop : Icons.camera_alt),
                        label: Text(_isScanning ? 'Arrêter le scan' : 'Scanner un code-barres'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Scanner camera view
              if (_isScanning)
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onBarcodeDetected,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Affichage du chargement
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              // Affichage de l'erreur
              if (_errorMessage != null && !_isLoading)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Affichage du produit trouvé
              if (_scannedProduct != null && !_isLoading)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produit trouvé:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        // Image du produit si disponible
                        if (_scannedProduct!.imageUrl.isNotEmpty)
                          Center(
                            child: Image.network(
                              _scannedProduct!.imageUrl,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported,
                                  size: 100,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Détails du produit
                        ProductInfoRow(
                          label: 'Nom:',
                          value: _scannedProduct!.name,
                        ),
                        ProductInfoRow(
                          label: 'Marque:',
                          value: _scannedProduct!.brand,
                        ),
                        ProductInfoRow(
                          label: 'Catégorie:',
                          value: _scannedProduct!.category,
                        ),
                        ProductInfoRow(
                          label: 'Prix:',
                          value: '${_scannedProduct!.price.toStringAsFixed(2)} €',
                        ),
                        ProductInfoRow(
                          label: 'Quantité en stock:',
                          value: _scannedProduct!.quantity.toString(),
                        ),
                        const SizedBox(height: 16),
                        // Bouton pour ajouter au panier
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showAddToCartDialog(context);
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Ajouter au panier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleScanner() {
    setState(() {
      _isScanning = !_isScanning;
      if (!_isScanning) {
        _errorMessage = null;
      }
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isLoading) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? barcodeScanRes = barcodes.first.rawValue;
    if (barcodeScanRes == null) return;
    
    // Arrêter le scanner une fois un code détecté
    setState(() {
      _isScanning = false;
      _isLoading = true;
      _errorMessage = null;
      _scannedBarcode = barcodeScanRes;
    });
    
    try {
      // Rechercher le produit dans l'API
      final productNotifier = ref.read(productProvider.notifier);
      final product = await productNotifier.scanProduct(barcodeScanRes);
      
      // Mettre à jour l'UI
      setState(() {
        _isLoading = false;
        _scannedProduct = product;
        _errorMessage = product == null
            ? 'Ce produit n\'est pas disponible à la vente dans notre magasin. Veuillez contacter un responsable si vous souhaitez l\'acheter.'
            : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du scan: $e';
        debugPrint(_errorMessage);
      });
    }
  }

  void _processManualBarcode(BuildContext context) async {
    final String barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un code-barres'),
        ),
      );
      return;
    }
    
    // Cacher le clavier
    FocusScope.of(context).unfocus();
    
    // Arrêter le scanner s'il est en cours
    setState(() {
      _isScanning = false;
      _isLoading = true;
      _errorMessage = null;
      _scannedBarcode = barcode;
    });
    
    try {
      // Rechercher le produit dans l'API
      final productNotifier = ref.read(productProvider.notifier);
      final product = await productNotifier.scanProduct(barcode);
      
      // Mettre à jour l'UI
      setState(() {
        _isLoading = false;
        _scannedProduct = product;
        _errorMessage = product == null
            ? 'Ce produit n\'est pas disponible à la vente dans notre magasin. Veuillez contacter un responsable si vous souhaitez l\'acheter.'
            : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du scan: $e';
        debugPrint(_errorMessage);
      });
    }
  }

  void _showAddToCartDialog(BuildContext context) {
    if (_scannedProduct == null) return;
    
    final product = _scannedProduct!;
    final availableStock = product.quantity;
    
    // Contrôleur pour le champ de texte de quantité
    final quantityController = TextEditingController(text: '1');
    
    // Prix total initial (prix unitaire * 1)
    ValueNotifier<double> totalPrice = ValueNotifier(product.price);
    
    // Mettre à jour le prix total lorsque la quantité change
    void updateTotalPrice(String value) {
      final quantity = int.tryParse(value) ?? 0;
      totalPrice.value = quantity * product.price;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter au panier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prix unitaire: ${product.price.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'En stock: $availableStock',
              style: TextStyle(
                fontSize: 14,
                color: availableStock < 5 ? Colors.red : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: updateTotalPrice,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: totalPrice,
              builder: (context, value, child) {
                return Text(
                  'Prix total: ${value.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Récupérer la quantité saisie
              final quantity = int.tryParse(quantityController.text) ?? 0;
              
              // Vérifier que la quantité est valide
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir une quantité valide'),
                  ),
                );
                return;
              }
              
              // Vérifier que la quantité ne dépasse pas le stock disponible
              if (quantity > availableStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La quantité demandée (${quantity}) dépasse le stock disponible (${availableStock})'),
                  ),
                );
                return;
              }
              
              // Ajouter au panier
              ref.read(cartProvider.notifier).addToCart(product, quantity);
              
              // Fermer la boîte de dialogue
              Navigator.of(context).pop();
              
              // Afficher une confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} ajouté au panier (${quantity}x)'),
                  action: SnackBarAction(
                    label: 'Voir le panier',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/cart');
                    },
                  ),
                ),
              );
            },
            child: const Text('Ajouter'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher une ligne d'information produit
class ProductInfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const ProductInfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 
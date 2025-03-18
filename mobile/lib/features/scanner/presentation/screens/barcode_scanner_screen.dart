import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../providers/product_provider.dart';
import '../../../products/domain/models/product.dart';

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
                              // TODO: Implémenter l'ajout au panier
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fonctionnalité à implémenter'),
                                ),
                              );
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
            ? 'Aucun produit trouvé avec ce code-barres'
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
            ? 'Aucun produit trouvé avec ce code-barres'
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
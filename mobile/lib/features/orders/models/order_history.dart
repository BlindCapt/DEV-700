import 'package:flutter/foundation.dart';

// Statut possible d'une facture
enum InvoiceStatus {
  pending, // En attente
  paid,    // Payée
  cancelled, // Annulée
  refunded   // Remboursée
}

// Extension pour convertir une chaîne en statut de facture
extension InvoiceStatusExtension on String {
  InvoiceStatus toInvoiceStatus() {
    switch (this.toLowerCase()) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'refunded':
        return InvoiceStatus.refunded;
      case 'pending':
      default:
        return InvoiceStatus.pending;
    }
  }
}

// Modèle pour un produit
class Product {
  final int id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double price;
  
  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.price,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    debugPrint('Produit JSON: $json');
    return Product(
      id: json['id'],
      name: json['name'] ?? 'Produit sans nom',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] is int) 
        ? (json['price'] as int).toDouble() 
        : json['price']?.toDouble() ?? 0.0,
    );
  }
}

// Modèle pour un article du panier
class CartItem {
  final int id;
  final int quantity;
  final Product product;
  
  CartItem({
    required this.id,
    required this.quantity,
    required this.product,
  });
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    debugPrint('CartItem JSON: $json');
    return CartItem(
      id: json['id'],
      quantity: json['quantity'],
      product: Product.fromJson(json['product'] ?? {}),
    );
  }
}

// Modèle pour un panier
class Cart {
  final int id;
  final List<CartItem> items;
  
  Cart({
    required this.id,
    required this.items,
  });
  
  factory Cart.fromJson(Map<String, dynamic> json) {
    debugPrint('Cart JSON: $json');
    List<CartItem> items = [];
    
    // Vérifie si le JSON a une clé 'cartItems' ou 'items'
    var itemsJson = json['cartItems'] ?? json['items'] ?? [];
    
    if (itemsJson is List) {
      items = itemsJson.map((item) => CartItem.fromJson(item)).toList();
    }
    
    debugPrint('Nombre d\'articles trouvés dans le panier: ${items.length}');
    
    return Cart(
      id: json['id'],
      items: items,
    );
  }
  
  // Calculer le total du panier
  double get total {
    return items.fold(0, (sum, item) => sum + (item.quantity * item.product.price));
  }
}

// Modèle pour une facture
class Invoice {
  final int id;
  final String invoiceNumber;
  final int mobileUserId;
  final int cartId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final double totalAmount;
  final InvoiceStatus status;
  final String? paymentMethod;
  final String? paymentReference;
  final String? billingAddress;
  final String? notes;
  final Cart? cart;
  
  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.mobileUserId,
    required this.cartId,
    required this.createdAt,
    this.paidAt,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentReference,
    this.billingAddress,
    this.notes,
    this.cart,
  });
  
  factory Invoice.fromJson(Map<String, dynamic> json) {
    debugPrint('Invoice JSON: $json');
    
    // Gérer le cas où le cart est intégré ou référencé sous différentes clés
    var cartData = json['cart'];
    if (cartData == null) {
      // Si 'cart' n'existe pas, essayons de le reconstruire à partir des autres données
      if (json['cartItems'] != null) {
        cartData = {
          'id': json['cartId'] ?? 0,
          'cartItems': json['cartItems']
        };
      }
    }
    
    debugPrint('Cart data extraite: $cartData');
    
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      mobileUserId: json['mobileUserId'] ?? 0,
      cartId: json['cartId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      totalAmount: (json['totalAmount'] is int) 
        ? (json['totalAmount'] as int).toDouble() 
        : json['totalAmount']?.toDouble() ?? 0.0,
      status: (json['status'] as String? ?? 'pending').toInvoiceStatus(),
      paymentMethod: json['paymentMethod'],
      paymentReference: json['paymentReference'],
      billingAddress: json['billingAddress'],
      notes: json['notes'],
      cart: cartData != null ? Cart.fromJson(cartData) : null,
    );
  }
} 
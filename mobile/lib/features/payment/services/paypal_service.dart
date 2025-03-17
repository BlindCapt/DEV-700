import 'package:flutter/material.dart';
// import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
import '../../../core/constants/app_constants.dart';

/// Service pour gérer les paiements avec PayPal
class PaypalService {
  // Méthode pour effectuer un paiement avec PayPal
  static Future<bool> processPayment({
    required BuildContext context,
    required String orderName,
    required double amount,
    required String currencyCode,
    String? userFirstName,
    String? userLastName,
    String? userEmail,
  }) async {
    // Version temporaire pour le test
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paiement simulé de $amount $currencyCode pour $orderName'),
        duration: const Duration(seconds: 3),
      ),
    );
    return true;
    
    /* Version complète (commentée pour le test)
    bool paymentSuccess = false;

    try {
      NavigatorState? navigator = Navigator.of(context);
      
      final result = await navigator.push(
        MaterialPageRoute(
          builder: (context) => PaypalCheckout(
            sandboxMode: AppConstants.paypalSandbox,
            clientId: AppConstants.paypalClientId,
            secretKey: AppConstants.paypalSecret,
            returnURL: "success.flutter.dev",
            cancelURL: "cancel.flutter.dev",
            transactions: [
              {
                "amount": {
                  "total": amount.toStringAsFixed(2),
                  "currency": currencyCode,
                  "details": {
                    "subtotal": amount.toStringAsFixed(2),
                    "shipping": '0.00',
                    "shipping_discount": 0
                  }
                },
                "description": "Paiement pour $orderName",
                "item_list": {
                  "items": [
                    {
                      "name": orderName,
                      "quantity": 1,
                      "price": amount.toStringAsFixed(2),
                      "currency": currencyCode
                    }
                  ],
                }
              }
            ],
            note: "Merci pour votre commande!",
            onSuccess: (Map params) async {
              // Les paramètres contiennent les informations de transaction
              print("Paiement PayPal réussi: $params");
              paymentSuccess = true;
              navigator.pop(); // Retour à l'écran précédent
            },
            onError: (error) {
              print("Erreur PayPal: $error");
              navigator.pop(); // Retour à l'écran précédent
            },
            onCancel: () {
              print("Paiement PayPal annulé");
              navigator.pop(); // Retour à l'écran précédent
            },
          ),
        ),
      );
      
      return paymentSuccess;
    } catch (e) {
      print("Exception dans le processus PayPal: $e");
      return false;
    }
    */
  }
} 
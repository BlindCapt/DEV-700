/// Classe contenant toutes les constantes de l'application
class AppConstants {
  // Constantes de navigation
  static const String homeRoute = '/';
  static const String productsRoute = '/products';
  static const String cartRoute = '/cart';
  static const String paymentRoute = '/payment';
  static const String profileRoute = '/profile';
  
  // Constantes pour Hive
  static const String cartBoxName = 'cart';
  static const String userBoxName = 'user';
  static const String settingsBoxName = 'settings';
  
  // Constantes pour l'API
  static const String apiBaseUrl = 'http://localhost:5094/api';
  static const String productsEndpoint = '/products';
  static const String authEndpoint = '/auth';
  
  // Constantes pour PayPal
  static const String paypalClientId = 'YOUR_PAYPAL_CLIENT_ID';
  static const String paypalSecret = 'YOUR_PAYPAL_SECRET';
  static const bool paypalSandbox = true; // true pour l'environnement de test
} 
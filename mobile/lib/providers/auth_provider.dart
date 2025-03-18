import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../features/auth/data/api/auth_api_service.dart';
import '../features/auth/domain/models/api_user.dart';
import '../features/cart/data/api/cart_api_service.dart';

// État d'authentification
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final ApiUser? user;
  final String? currentApiUrl;
  final String? lastErrorMessage;
  
  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.currentApiUrl,
    this.lastErrorMessage,
  });

  // Méthode pour copier l'état avec des propriétés modifiées
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    ApiUser? user,
    String? currentApiUrl,
    String? lastErrorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      currentApiUrl: currentApiUrl ?? this.currentApiUrl,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }
}

// Provider pour le service API
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

// Provider pour le service API du panier
final cartApiServiceProvider = Provider<CartApiService>((ref) {
  return CartApiService();
});

// Notifier pour gérer l'état d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;
  final CartApiService _cartService;
  
  AuthNotifier(this._authService, this._cartService) : super(AuthState()) {
    // Initialisation - Vérifier s'il y a déjà un token valide
    restoreUserSession();
  }
  
  // Méthode pour restaurer la session utilisateur si un token valide existe
  Future<void> restoreUserSession() async {
    debugPrint('==== DEBUT restoreUserSession() ====');
    
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint('Vérification de la validité du token');
      final hasValidToken = await _authService.hasValidToken();
      
      if (hasValidToken) {
        debugPrint('Token valide trouvé, tentative de restauration de la session');
        
        // Ping pour obtenir l'URL actuelle
        await _authService.testPing();
        debugPrint('Ping réussi, URL API actuelle: ${_authService.currentApiUrl}');
        
        // Récupérer les informations de l'utilisateur
        debugPrint('Récupération des informations utilisateur');
        final user = await _authService.getCurrentUser();
        
        if (user != null) {
          debugPrint('Informations utilisateur récupérées: ${user.email}');
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: user,
            currentApiUrl: _authService.currentApiUrl,
            lastErrorMessage: _authService.lastErrorMessage,
          );
          
          // Initialiser le panier de l'utilisateur
          _initializeCart();
          
          debugPrint('Session restaurée avec succès pour l\'utilisateur: ${user.email}');
          debugPrint('État d\'authentification: ${state.isAuthenticated}');
        } else {
          debugPrint('Impossible de récupérer les informations de l\'utilisateur');
          await logout(); // Déconnexion si les informations utilisateur ne peuvent pas être récupérées
        }
      } else {
        debugPrint('Pas de token valide trouvé ou token expiré');
        state = state.copyWith(
          isLoading: false,
          lastErrorMessage: _authService.lastErrorMessage,
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la restauration de session: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la restauration de session: $e',
      );
    }
    
    debugPrint('==== FIN restoreUserSession(), état auth: ${state.isAuthenticated} ====');
  }
  
  // Méthode pour se connecter
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Tester la connexion au serveur d'abord
      final pingSuccess = await _authService.testPing();
      if (!pingSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible de se connecter au serveur',
          lastErrorMessage: _authService.lastErrorMessage,
        );
        return false;
      }
      
      final user = await _authService.login(email, password);
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        currentApiUrl: _authService.currentApiUrl,
      );
      
      // Initialiser le panier de l'utilisateur après connexion réussie
      _initializeCart();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: $e',
      );
      return false;
    }
  }
  
  // Méthode pour initialiser le panier de l'utilisateur
  Future<void> _initializeCart() async {
    debugPrint('==== DEBUT _initializeCart() ====');
    try {
      // Attendre un court instant pour s'assurer que la session est complètement établie
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier que l'utilisateur est bien authentifié
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('Aucun token trouvé pour initialiser le panier');
        debugPrint('==== FIN _initializeCart(): Echec (aucun token) ====');
        return;
      }
      
      debugPrint('Token disponible pour initialiser le panier (longueur: ${token.length})');
      
      // Système de tentatives multiples pour assurer la création du panier
      bool panierInitialise = false;
      int maxTentatives = 3;
      
      for (int tentative = 1; tentative <= maxTentatives && !panierInitialise; tentative++) {
        debugPrint('Tentative d\'initialisation du panier ${tentative}/$maxTentatives');
        
        // Étape 1: Essayer de récupérer un panier existant
        var cartItems = await _cartService.fetchCart();
        
        // Étape 2: Si le panier existe, nous avons terminé
        if (cartItems.isNotEmpty) {
          debugPrint('Panier existant récupéré: ${cartItems.length} articles');
          panierInitialise = true;
          break;
        }
        
        // Étape 3: Si aucun panier n'existe, en créer un nouveau
        debugPrint('Aucun panier existant trouvé, création d\'un nouveau panier');
        bool success = await _cartService.createCart();
        
        if (success) {
          debugPrint('Nouveau panier créé avec succès');
          
          // Vérifier que le panier a bien été créé en le récupérant
          await Future.delayed(const Duration(milliseconds: 500)); // Attendre que le serveur traite la création
          cartItems = await _cartService.fetchCart();
          
          if (cartItems.isNotEmpty) {
            debugPrint('Panier récupéré après création: ${cartItems.length} articles');
            panierInitialise = true;
          } else {
            debugPrint('Panier créé mais impossible à récupérer. Réessai...');
          }
        } else {
          debugPrint('Échec de la création du panier à la tentative $tentative');
          
          // Attendre un peu plus longtemps entre chaque tentative
          await Future.delayed(Duration(seconds: tentative)); 
        }
      }
      
      if (panierInitialise) {
        debugPrint('Panier initialisé avec succès');
      } else {
        debugPrint('Impossible d\'initialiser le panier après $maxTentatives tentatives');
      }
      
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du panier: $e');
    }
    
    debugPrint('==== FIN _initializeCart() ====');
  }

  // Méthode pour s'inscrire
  Future<bool> register({
    required String email,
    required String password, 
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    debugPrint('Tentative d\'inscription avec email: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Tester le ping d'abord pour trouver la meilleure URL
      debugPrint('Test de ping avant inscription');
      await _authService.testPing();
      
      debugPrint('Ping réussi, tentative d\'inscription');
      
      // Mettre à jour l'URL actuelle
      state = state.copyWith(
        currentApiUrl: _authService.currentApiUrl,
        lastErrorMessage: _authService.lastErrorMessage,
      );
      
      // Tentative d'inscription à l'API
      final result = await _authService.register(
        email: email, 
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      debugPrint('Inscription réussie: $result');
      
      state = state.copyWith(
        isLoading: false,
        error: null,
        lastErrorMessage: null,
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      String errorMessage = e.toString();
      
      // Personnaliser le message d'erreur
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.split('Exception:')[1].trim();
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        lastErrorMessage: _authService.lastErrorMessage,
      );
      return false;
    }
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    debugPrint('Déconnexion de l\'utilisateur: ${state.user?.email}');
    
    // Supprimer le token JWT
    await _authService.logout();
    
    // Réinitialiser l'état
    state = AuthState();
  }

  // Vérifier si l'utilisateur est déjà connecté
  Future<bool> checkAuth() async {
    await restoreUserSession();
    return state.isAuthenticated;
  }
}

// Provider pour l'état d'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  final cartService = ref.watch(cartApiServiceProvider);
  return AuthNotifier(authService, cartService);
}); 
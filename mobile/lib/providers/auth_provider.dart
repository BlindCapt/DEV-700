import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../features/auth/data/api/auth_api_service.dart';
import '../features/auth/domain/models/api_user.dart';

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

// Notifier pour gérer l'état d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;
  
  AuthNotifier(this._authService) : super(AuthState()) {
    // Initialisation - Vérifier s'il y a déjà un token valide
    restoreUserSession();
  }
  
  // Méthode pour restaurer la session utilisateur si un token valide existe
  Future<void> restoreUserSession() async {
    debugPrint('==== DÉBUT restoreUserSession() ====');
    
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
      debugPrint('Erreur lors de la restauration de la session: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastErrorMessage: _authService.lastErrorMessage,
      );
    }
    
    debugPrint('==== FIN restoreUserSession(), état auth: ${state.isAuthenticated} ====');
  }

  // Méthode pour se connecter
  Future<bool> login(String email, String password) async {
    debugPrint('Tentative de connexion avec email: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Tester le ping d'abord pour trouver la meilleure URL
      debugPrint('Test de ping avant connexion');
      await _authService.testPing();
      
      // Mettre à jour l'URL actuelle
      state = state.copyWith(
        currentApiUrl: _authService.currentApiUrl,
        lastErrorMessage: _authService.lastErrorMessage,
      );
      
      // Tentative de connexion à l'API
      debugPrint('Tentative de connexion à l\'API');
      final user = await _authService.login(email, password);
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        error: null,
        lastErrorMessage: null,
      );
      
      debugPrint('Connexion réussie à l\'API avec token: ${user.token}');
      return true;
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      String errorMessage = e.toString();
      
      // Personnaliser le message d'erreur
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.split('Exception:')[1].trim();
      }
      
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: errorMessage,
        lastErrorMessage: _authService.lastErrorMessage,
      );
      return false;
    }
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
  return AuthNotifier(authService);
}); 
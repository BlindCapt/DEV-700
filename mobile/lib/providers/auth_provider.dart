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
  final bool isOfflineMode;
  final String? currentApiUrl;
  
  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.isOfflineMode = false,
    this.currentApiUrl,
  });

  // Méthode pour copier l'état avec des propriétés modifiées
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    ApiUser? user,
    bool? isOfflineMode,
    String? currentApiUrl,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      currentApiUrl: currentApiUrl ?? this.currentApiUrl,
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
  
  AuthNotifier(this._authService) : super(AuthState());

  // Méthode pour se connecter
  Future<bool> login(String email, String password) async {
    debugPrint('Tentative de connexion avec email: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Tester le ping d'abord pour trouver la meilleure URL et déterminer si on est en ligne
      debugPrint('Test de ping avant connexion');
      bool pingSuccess = await _authService.testPing();
      
      if (!pingSuccess) {
        debugPrint('Aucun serveur n\'a répondu au ping');
        // On est probablement en mode hors ligne
        state = state.copyWith(isOfflineMode: true);
      } else {
        debugPrint('Ping réussi, tentative de connexion');
        state = state.copyWith(isOfflineMode: false);
      }
      
      // Mettre à jour l'URL actuelle
      state = state.copyWith(currentApiUrl: _authService.currentApiUrl);
      
      // Tentative de connexion à l'API
      debugPrint('Tentative de connexion à l\'API');
      final user = await _authService.login(email, password);
      
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        error: null,
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
      bool pingSuccess = await _authService.testPing();
      
      if (!pingSuccess) {
        debugPrint('Aucun serveur n\'a répondu au ping');
        if (state.isOfflineMode) {
          throw Exception('Vous êtes en mode hors ligne. Veuillez vous connecter à Internet pour vous inscrire.');
        }
      }
      
      debugPrint('Ping réussi, tentative d\'inscription');
      
      // Mettre à jour l'URL actuelle
      state = state.copyWith(currentApiUrl: _authService.currentApiUrl);
      
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
      );
      return false;
    }
  }

  // Méthode pour basculer en mode hors ligne manuellement
  void toggleOfflineMode(bool enabled) {
    debugPrint('Bascule du mode hors ligne: $enabled');
    _authService.setOfflineMode(enabled);
    state = state.copyWith(isOfflineMode: enabled);
  }

  // Méthode pour se déconnecter
  void logout() {
    debugPrint('Déconnexion de l\'utilisateur: ${state.user?.email}');
    state = AuthState(isOfflineMode: state.isOfflineMode);
  }

  // Vérifier si l'utilisateur est déjà connecté (à implémenter avec un jeton stocké)
  Future<bool> checkAuth() async {
    // Ici, vous pourriez vérifier le stockage local pour un jeton d'authentification
    debugPrint('Vérification de l\'authentification - isAuthenticated: ${state.isAuthenticated}');
    return state.isAuthenticated;
  }
}

// Provider pour l'état d'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  return AuthNotifier(authService);
}); 
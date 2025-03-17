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
  
  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  // Méthode pour copier l'état avec des propriétés modifiées
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    ApiUser? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
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
      // Tester le ping d'abord pour trouver la meilleure URL
      debugPrint('Test de ping avant connexion');
      bool pingSuccess = await _authService.testPing();
      
      if (!pingSuccess) {
        debugPrint('Aucun serveur n\'a répondu au ping');
      } else {
        debugPrint('Ping réussi, tentative de connexion');
      }
      
      // Tentative de connexion à l'API avec plusieurs essais
      debugPrint('Tentative de connexion à l\'API');
      
      // Essayer avec plusieurs URLs
      Exception? lastError;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          if (attempt > 0) {
            // Basculer vers l'URL suivante après le premier essai
            _authService.switchToNextUrl();
          }
          
          final user = await _authService.login(email, password);
          
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: user,
          );
          
          debugPrint('Connexion réussie à l\'API avec token: ${user.token}');
          return true;
        } catch (apiError) {
          lastError = apiError is Exception ? apiError : Exception(apiError.toString());
          debugPrint('Erreur de connexion à l\'API (tentative ${attempt + 1}/3): $apiError');
          // Continuez à la prochaine itération pour essayer avec une autre URL
        }
      }
      
      // Si nous arrivons ici, toutes les tentatives ont échoué
      debugPrint('Toutes les tentatives de connexion à l\'API ont échoué');
      
      // Mode de connexion de secours (pour les tests)
      if (email == 'admin' && password == 'admin') {
        debugPrint('Mode de connexion de secours (admin/admin)');
        await Future.delayed(const Duration(seconds: 1));
        
        // Créer un utilisateur fictif
        final fakeUser = ApiUser(
          id: 0,
          email: 'admin@dev700.com',
          firstName: 'Admin',
          lastName: 'Test',
          phoneNumber: '0123456789',
          token: 'fake-token',
        );
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: fakeUser,
        );
        
        debugPrint('Connexion réussie en mode de secours');
        return true;
      }
      
      // Si ce n'est pas le mode de secours, propager l'erreur
      throw lastError ?? Exception('Erreur de connexion');
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString().contains('Exception:') 
            ? e.toString().split('Exception:')[1].trim() 
            : 'Erreur de connexion: ${e.toString()}',
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
        throw Exception('Impossible de contacter le serveur. Veuillez vérifier votre connexion réseau.');
      }
      
      debugPrint('Ping réussi, tentative d\'inscription');
      
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
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('Exception:') 
            ? e.toString().split('Exception:')[1].trim() 
            : 'Erreur d\'inscription: ${e.toString()}',
      );
      return false;
    }
  }

  // Méthode pour se déconnecter
  void logout() {
    debugPrint('Déconnexion de l\'utilisateur: ${state.user?.email}');
    state = AuthState();
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
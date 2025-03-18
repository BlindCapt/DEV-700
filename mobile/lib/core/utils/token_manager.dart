import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Cache en mémoire du token pour éviter des lectures multiples
  String? _cachedToken;

  // Récupérer le token JWT
  Future<String?> getToken() async {
    try {
      // Vérifier d'abord le cache en mémoire
      if (_cachedToken != null) {
        debugPrint('Récupération du token JWT depuis le cache (longueur: ${_cachedToken!.length})');
        return _cachedToken;
      }
      
      // Si pas en cache, lire depuis le stockage sécurisé
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        // Mettre en cache pour les prochaines utilisations
        _cachedToken = token;
        debugPrint('Récupération du token JWT: Trouvé (longueur: ${token.length})');
      } else {
        debugPrint('Récupération du token JWT: Non trouvé');
      }
      
      return _cachedToken;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token: $e');
      // Retourner le token en cache même en cas d'erreur si disponible
      if (_cachedToken != null) {
        debugPrint('Utilisation du token en cache malgré l\'erreur');
        return _cachedToken;
      }
      return null;
    }
  }

  // Enregistrer le token JWT
  Future<void> saveToken(String token) async {
    try {
      // Mettre à jour le cache en mémoire
      _cachedToken = token;
      
      // Enregistrer dans le stockage sécurisé
      await _storage.write(key: _tokenKey, value: token);
      debugPrint('Token JWT enregistré (longueur: ${token.length})');
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du token: $e');
    }
  }

  // Récupérer le refresh token
  Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      return refreshToken;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du refresh token: $e');
      return null;
    }
  }

  // Enregistrer le refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du refresh token: $e');
    }
  }

  // Effacer tous les tokens (déconnexion)
  Future<void> clearTokens() async {
    try {
      // Vider le cache en mémoire
      _cachedToken = null;
      
      // Supprimer du stockage sécurisé
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      debugPrint('Tokens effacés');
    } catch (e) {
      debugPrint('Erreur lors de l\'effacement des tokens: $e');
    }
  }

  // Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
} 
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/token_manager.dart';
import '../../../../../core/utils/api_url_resolver.dart';

import '../../domain/models/api_user.dart';

class AuthApiService {
  // Gestionnaire de token unifié
  final TokenManager _tokenManager = TokenManager();
  final ApiUrlResolver _apiUrlResolver = ApiUrlResolver();
  
  // Durée de timeout des requêtes
  static const Duration _timeout = Duration(seconds: 2);
  
  // URL actuelle (obtenue dynamiquement)
  String _currentApiUrl = 'https://0335-163-5-3-101.ngrok-free.app';
  
  // Getter pour l'URL actuelle
  String get currentApiUrl => _currentApiUrl;
  
  // Information sur la dernière erreur
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;
  
  // Méthodes pour la gestion du token JWT en utilisant TokenManager
  Future<void> saveToken(String token) async {
    await _tokenManager.saveToken(token);
    
    // Sauvegarder une copie dans Hive pour la persistance des sessions
    final box = Hive.box(AppConstants.userBoxName);
    await box.put('jwt_token', token);
    debugPrint('Token JWT sauvegardé dans le stockage local et TokenManager');
  }
  
  Future<String?> getToken() async {
    // Toujours utiliser TokenManager pour récupérer le token
    final token = await _tokenManager.getToken();
    
    // Si TokenManager ne trouve pas le token, essayer de le récupérer depuis Hive
    if (token == null) {
      final box = Hive.box(AppConstants.userBoxName);
      final savedToken = box.get('jwt_token');
      
      if (savedToken != null) {
        // Restaurer le token dans TokenManager
        debugPrint('Token trouvé dans Hive mais pas dans TokenManager, restauration...');
        await _tokenManager.saveToken(savedToken);
        return savedToken;
      }
      
      return null;
    }
    
    return token;
  }
  
  Future<bool> hasValidToken() async {
    debugPrint('==== DÉBUT hasValidToken() ====');
    final token = await getToken();
    if (token == null) {
      debugPrint('==== FIN hasValidToken(): Aucun token ====');
      return false;
    }
    
    // Vérifier si le token est valide en faisant un appel simple à l'API
    try {
      debugPrint('Vérification de la validité du token');
      // Mettre à jour l'URL actuelle de l'API
      _currentApiUrl = await _apiUrlResolver.getApiUrl();
      
      final response = await http.get(
        Uri.parse('$_currentApiUrl/api/mobile/user/validate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      ).timeout(_timeout);
      
      bool isValid = response.statusCode == 200;
      debugPrint('==== FIN hasValidToken(): ${isValid ? "Token valide" : "Token invalide"} ====');
      return isValid;
    } catch (e) {
      debugPrint('Erreur lors de la validation du token: $e');
      debugPrint('==== FIN hasValidToken(): Exception ====');
      return false;
    }
  }
  
  Future<void> clearToken() async {
    // Effacer dans TokenManager et dans Hive
    await _tokenManager.clearTokens();
    
    final box = Hive.box(AppConstants.userBoxName);
    await box.delete('jwt_token');
    debugPrint('Token JWT supprimé du TokenManager et du stockage local');
  }
  
  // Créer un client HTTP avec le token d'authentification s'il existe
  Future<http.Client> getAuthenticatedClient() async {
    final client = http.Client();
    final token = await getToken();
    
    if (token != null) {
      return _AuthenticatedClient(client, token);
    }
    
    return client;
  }
  
  // Tester si le serveur répond (fonction de ping)
  Future<bool> testPing() async {
    try {
      // Obtenir l'URL de l'API résolue
      _currentApiUrl = await _apiUrlResolver.getApiUrl();
      
      debugPrint('Test de ping avec: $_currentApiUrl/api/diagnostic/ping');
      
      final response = await http.get(
        Uri.parse('$_currentApiUrl/api/diagnostic/ping'),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        debugPrint('Ping réussi avec $_currentApiUrl: ${response.body}');
        _lastErrorMessage = null;
        return true;
      } else {
        _lastErrorMessage = 'Échec du ping avec $_currentApiUrl: Code ${response.statusCode}';
        debugPrint(_lastErrorMessage ?? '');
        return false;
      }
    } on TimeoutException {
      _lastErrorMessage = 'Le ping a expiré après ${_timeout.inSeconds} secondes pour $_currentApiUrl';
      debugPrint(_lastErrorMessage ?? '');
      return false;
    } catch (e) {
      _lastErrorMessage = 'Erreur lors du ping de $_currentApiUrl: $e';
      debugPrint(_lastErrorMessage ?? '');
      return false;
    }
  }

  // Fonction d'inscription
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    // Obtenir l'URL de l'API résolue
    _currentApiUrl = await _apiUrlResolver.getApiUrl();
    
    final url = '$_currentApiUrl/api/mobile/auth/register';
    debugPrint('Tentative d\'inscription à l\'URI: $url');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Inscription réussie');
        _lastErrorMessage = null;
        return true;
      } else {
        _lastErrorMessage = 'Échec de l\'inscription: ${response.statusCode} - ${response.body}';
        debugPrint(_lastErrorMessage ?? '');
        throw Exception(_lastErrorMessage);
      }
    } on TimeoutException {
      _lastErrorMessage = 'Délai d\'attente dépassé lors de l\'inscription à $url';
      debugPrint(_lastErrorMessage ?? '');
      throw Exception(_lastErrorMessage);
    } catch (e) {
      _lastErrorMessage = 'Erreur lors de l\'inscription: $e';
      debugPrint(_lastErrorMessage ?? '');
      rethrow;
    }
  }
  
  // Fonction de connexion
  Future<ApiUser> login(String email, String password) async {
    // Obtenir l'URL de l'API résolue
    _currentApiUrl = await _apiUrlResolver.getApiUrl();
    
    final url = '$_currentApiUrl/api/mobile/auth/login';
    debugPrint('Tentative de connexion à l\'URI: $url');
    debugPrint('Avec les données: email=$email, password=***');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Connexion réussie: ${response.body}');
        _lastErrorMessage = null;
        
        // La réponse contient un objet "user" et un "token" séparé
        final userData = data['user']; 
        final token = data['token'];
        
        // Sauvegarder le token pour les futures requêtes
        await saveToken(token);
        
        // Créer l'objet ApiUser
        final user = ApiUser(
          id: userData['id'] as int,
          email: userData['email'] as String,
          firstName: userData['firstName'] as String,
          lastName: userData['lastName'] as String,
          // Le phoneNumber peut être manquant dans la réponse de l'API
          phoneNumber: userData['phoneNumber'] ?? '0000000000',  // Valeur par défaut
          token: token,
        );
        
        // Sauvegarder les informations de l'utilisateur localement
        final box = Hive.box(AppConstants.userBoxName);
        await box.put('user_data', {
          'id': user.id,
          'email': user.email,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'phoneNumber': user.phoneNumber,
          'token': user.token,
        });
        debugPrint('Informations utilisateur sauvegardées localement');
        
        return user;
      } else {
        _lastErrorMessage = 'Échec de la connexion: ${response.statusCode} - ${response.body}';
        debugPrint(_lastErrorMessage ?? '');
        throw Exception(_lastErrorMessage);
      }
    } on TimeoutException {
      _lastErrorMessage = 'Délai d\'attente dépassé lors de la connexion à $url';
      debugPrint(_lastErrorMessage ?? '');
      throw Exception(_lastErrorMessage);
    } catch (e) {
      _lastErrorMessage = 'Erreur lors de la connexion à $url: $e';
      debugPrint(_lastErrorMessage ?? '');
      rethrow;
    }
  }
  
  // Méthode de déconnexion qui supprime le token
  Future<void> logout() async {
    await clearToken();
    
    // Supprimer les informations de l'utilisateur
    final box = Hive.box(AppConstants.userBoxName);
    await box.delete('user_data');
    
    debugPrint('Déconnexion réussie, token supprimé et informations utilisateur effacées');
  }
  
  // Ne pas oublier d'ajouter cette fonction de débogage
  void debugPrint(String message) {
    // Pour éviter des erreurs si le package flutter n'est pas importé
    print(message);
  }

  // Méthode pour mettre à jour dynamiquement l'URL ngrok
  void updateNgrokUrl(String newNgrokUrl) {
    if (_currentApiUrl != newNgrokUrl) {
      _currentApiUrl = newNgrokUrl;
      debugPrint('URL ngrok mise à jour: $newNgrokUrl');
    }
  }

  Future<ApiUser?> getCurrentUser() async {
    debugPrint('==== DÉBUT getCurrentUser() ====');
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('Pas de token trouvé pour récupérer l\'utilisateur');
        debugPrint('==== FIN getCurrentUser() : Aucun token ====');
        return null;
      }
      
      debugPrint('Token trouvé, longueur: ${token.length}');
      
      // Récupérer les informations de l'utilisateur stockées localement
      final box = Hive.box(AppConstants.userBoxName);
      final userData = box.get('user_data');
      
      if (userData != null) {
        debugPrint('Informations utilisateur trouvées dans le stockage local: ${userData.toString()}');
        try {
          final user = ApiUser.fromJson(Map<String, dynamic>.from(userData));
          debugPrint('Utilisateur récupéré depuis le stockage local: ${user.email}');
          debugPrint('==== FIN getCurrentUser() : Succès depuis stockage local ====');
          return user;
        } catch (e) {
          debugPrint('Erreur lors de la conversion des données utilisateur: $e');
        }
      } else {
        debugPrint('Aucune information utilisateur trouvée dans le stockage local');
      }
      
      // Si nous n'avons pas d'informations stockées localement, essayons de les récupérer depuis l'API
      try {
        debugPrint('Tentative de récupération depuis l\'API: ${currentApiUrl}/api/mobile/auth/me');
        final response = await http.get(
          Uri.parse('${currentApiUrl}/api/mobile/auth/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        debugPrint('Réponse de l\'API: ${response.statusCode}');
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          debugPrint('Données reçues de l\'API: $userData');
          final user = ApiUser.fromJson(userData);
          debugPrint('==== FIN getCurrentUser() : Succès depuis API ====');
          return user;
        } else {
          debugPrint('Erreur lors de la récupération de l\'utilisateur depuis l\'API: ${response.statusCode}');
          debugPrint('Body: ${response.body}');
          debugPrint('==== FIN getCurrentUser() : Échec depuis API ====');
          return null;
        }
      } catch (e) {
        debugPrint('Exception lors de la récupération de l\'utilisateur depuis l\'API: $e');
        debugPrint('==== FIN getCurrentUser() : Exception API ====');
        return null;
      }
    } catch (e) {
      debugPrint('Exception générale lors de la récupération de l\'utilisateur: $e');
      debugPrint('==== FIN getCurrentUser() : Exception générale ====');
      return null;
    }
  }
}

// Classe wrapper pour les requêtes authentifiées
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;
  
  _AuthenticatedClient(this._inner, this._token);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
} 
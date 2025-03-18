import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../../core/constants/app_constants.dart';

import '../../domain/models/api_user.dart';

class AuthApiService {
  // Liste des URLs API à essayer
  final List<String> _apiUrls = [
    'https://1ece-163-5-3-101.ngrok-free.app', // URL ngrok actuelle
  ];
  
  // Index de l'URL actuelle
  int _currentUrlIndex = 0;
  
  // Getter pour l'URL actuelle
  String get currentApiUrl => _apiUrls[_currentUrlIndex];
  
  // Information sur la dernière erreur
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;
  
  // Fonction pour basculer vers l'URL suivante
  void switchToNextUrl() {
    _currentUrlIndex = (_currentUrlIndex + 1) % _apiUrls.length;
    debugPrint('Basculé vers l\'URL alternative ${_currentUrlIndex + 1}: $currentApiUrl');
  }
  
  // Méthodes pour la gestion du token JWT
  Future<void> saveToken(String token) async {
    final box = Hive.box(AppConstants.userBoxName);
    await box.put('jwt_token', token);
    debugPrint('Token JWT sauvegardé dans le stockage local, longueur: ${token.length}');
  }
  
  Future<String?> getToken() async {
    final box = Hive.box(AppConstants.userBoxName);
    final token = box.get('jwt_token');
    debugPrint('Récupération du token JWT: ${token != null ? "Trouvé (longueur: ${token.length})" : "Aucun token"}');
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
      debugPrint('Vérification de la validité du token avec testPingWithToken');
      bool pingResult = await testPingWithToken(token);
      debugPrint('==== FIN hasValidToken(): ${pingResult ? "Token valide" : "Token invalide"} ====');
      return pingResult;
    } catch (e) {
      debugPrint('Erreur lors de la validation du token: $e');
      debugPrint('==== FIN hasValidToken(): Exception ====');
      return false;
    }
  }
  
  Future<bool> testPingWithToken(String token) async {
    // Tester chaque URL avec le token pour vérifier sa validité
    for (var i = 0; i < _apiUrls.length; i++) {
      _currentUrlIndex = i;
      final apiUrl = _apiUrls[i];
      
      debugPrint('Test de validité du token avec: $apiUrl/api/mobile/user/validate');
      
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/api/mobile/user/validate'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          debugPrint('Token valide pour $apiUrl');
          return true;
        } else {
          debugPrint('Token invalide pour $apiUrl: Code ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Erreur lors de la validation du token pour $apiUrl: $e');
      }
    }
    
    return false;
  }
  
  Future<void> clearToken() async {
    final box = Hive.box(AppConstants.userBoxName);
    await box.delete('jwt_token');
    debugPrint('Token JWT supprimé du stockage local');
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
  
  // Nouvelles méthodes pour la détection dynamique d'adresse IP
  Future<void> detectLocalApiServer() async {
    debugPrint('Tentative de détection automatique du serveur API...');
    
    // Récupérer l'adresse IP de l'appareil
    String? deviceIp = await _getDeviceIpAddress();
    if (deviceIp != null) {
      debugPrint('Adresse IP de l\'appareil: $deviceIp');
      
      // Extraire le préfixe du réseau (ex: 192.168.1)
      final parts = deviceIp.split('.');
      if (parts.length == 4) {
        final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        
        // Ajouter une nouvelle URL basée sur le réseau actuel
        final newApiUrl = 'http://$networkPrefix.1:5094';
        
        // Vérifier si cette URL existe déjà dans la liste
        if (!_apiUrls.contains(newApiUrl)) {
          debugPrint('Ajout d\'une nouvelle URL basée sur le réseau actuel: $newApiUrl');
          _apiUrls.insert(0, newApiUrl);
          _currentUrlIndex = 0;
        }
      }
    }
    
    // Ajouter quelques adresses IP courantes à essayer
    final commonIps = [
      'http://10.0.2.2:5094',      // Émulateur Android
      'http://192.168.0.1:5094',   // Routeur domestique courant
      'http://192.168.1.1:5094',   // Routeur domestique courant
    ];
    
    for (var ip in commonIps) {
      if (!_apiUrls.contains(ip)) {
        _apiUrls.add(ip);
      }
    }
  }
  
  Future<String?> _getDeviceIpAddress() async {
    try {
      // Récupérer toutes les interfaces réseau
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      
      // Filtrer pour obtenir les interfaces Wi-Fi et cellulaires
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Exclure les adresses de bouclage (127.x.x.x)
          if (!addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'adresse IP: $e');
    }
    return null;
  }
  
  // Tester si le serveur répond (fonction de ping)
  Future<bool> testPing() async {
    // Ajouter la détection d'adresse IP locale d'abord
    await detectLocalApiServer();
    
    // Tester chaque URL
    for (var i = 0; i < _apiUrls.length; i++) {
      _currentUrlIndex = i;
      final apiUrl = _apiUrls[i];
      
      debugPrint('Test de ping avec: $apiUrl/api/diagnostic/ping');
      
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/api/diagnostic/ping'),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          debugPrint('Ping réussi avec $apiUrl: ${response.body}');
          _lastErrorMessage = null;
          return true;
        } else {
          _lastErrorMessage = 'Échec du ping avec $apiUrl: Code ${response.statusCode}';
          debugPrint(_lastErrorMessage ?? '');
        }
      } on TimeoutException {
        _lastErrorMessage = 'Le ping a expiré après 5 secondes pour $apiUrl';
        debugPrint(_lastErrorMessage ?? '');
      } on SocketException catch (e) {
        if (e.message.contains('No route to host')) {
          _lastErrorMessage = 'Aucune route vers l\'hôte $apiUrl: ${e.message}';
        } else if (e.message.contains('Connection refused')) {
          _lastErrorMessage = 'Connexion refusée par $apiUrl: ${e.message}';
        } else {
          _lastErrorMessage = 'Erreur socket pour $apiUrl: ${e.message}';
        }
        debugPrint(_lastErrorMessage ?? '');
      } catch (e) {
        _lastErrorMessage = 'Erreur lors du ping de $apiUrl: $e';
        debugPrint(_lastErrorMessage ?? '');
      }
    }
    
    debugPrint('Aucun serveur n\'a répondu au ping');
    return false;
  }

  // Fonction d'inscription
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final url = '$currentApiUrl/api/mobile/auth/register';
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
      ).timeout(const Duration(seconds: 30));
      
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
    final url = '$currentApiUrl/api/mobile/auth/login';
    debugPrint('Tentative de connexion à l\'URI: $url');
    debugPrint('Avec les données: email=$email, password=***');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      
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
    } on SocketException catch (e) {
      if (e.message.contains('No route to host')) {
        _lastErrorMessage = 'Impossible d\'accéder au serveur $url: Aucune route vers l\'hôte';
      } else if (e.message.contains('Connection refused')) {
        _lastErrorMessage = 'Le serveur $url refuse la connexion';
      } else {
        _lastErrorMessage = 'Erreur de connexion à $url: ${e.message}';
      }
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
    if (_apiUrls.isNotEmpty) {
      _apiUrls[0] = newNgrokUrl;
      debugPrint('URL ngrok mise à jour: $newNgrokUrl');
      // Reset le compteur d'URL pour essayer la nouvelle URL en premier
      _currentUrlIndex = 0;
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
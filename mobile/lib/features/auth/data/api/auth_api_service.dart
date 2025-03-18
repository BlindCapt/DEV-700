import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/models/api_user.dart';

class AuthApiService {
  // Liste des URLs API à essayer
  final List<String> _apiUrls = [
    'https://b42e-163-5-3-101.ngrok-free.app', // URL ngrok actuelle
    // 'http://10.101.53.231:5094', // URL principale
    // 'http://192.168.132.1:5094', // URL alternative (VMware)
    // 'http://192.168.20.1:5094',  // URL alternative (VMware)
    // 'http://192.168.0.1:5094',   // URL locale (réseau domestique)
    // 'http://10.0.2.2:5094',      // URL pour émulateur Android
  ];
  
  // Index de l'URL actuelle
  int _currentUrlIndex = 0;
  
  // Getter pour l'URL actuelle
  String get currentApiUrl => _apiUrls[_currentUrlIndex];
  
  // Fonction pour basculer vers l'URL suivante
  void switchToNextUrl() {
    _currentUrlIndex = (_currentUrlIndex + 1) % _apiUrls.length;
    debugPrint('Basculé vers l\'URL alternative ${_currentUrlIndex + 1}: $currentApiUrl');
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
    
    // Si l'appareil est connecté à Internet, ajouter l'option de serveur externe
    bool hasInternet = await _checkInternetConnectivity();
    if (hasInternet) {
      const externalApiUrl = 'https://votreserveur.com/api'; // Remplacez par votre serveur externe réel
      if (!_apiUrls.contains(externalApiUrl)) {
        debugPrint('Ajout de l\'URL du serveur externe: $externalApiUrl');
        _apiUrls.add(externalApiUrl);
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
  
  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
  
  // Mode de fonctionnement hors ligne (cache)
  bool _offlineMode = false;
  
  // Activer/désactiver le mode hors ligne
  void setOfflineMode(bool enabled) {
    _offlineMode = enabled;
    debugPrint('Mode hors ligne ${_offlineMode ? 'activé' : 'désactivé'}');
  }
  
  // Tester si le serveur répond (fonction de ping)
  Future<bool> testPing() async {
    // Si en mode hors ligne, ne pas tester le ping
    if (_offlineMode) {
      debugPrint('Mode hors ligne actif, ping ignoré');
      return false;
    }
    
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
          return true;
        } else {
          debugPrint('Échec du ping avec $apiUrl: Code ${response.statusCode}');
        }
      } on TimeoutException {
        debugPrint('Le ping a expiré après 5 secondes pour $apiUrl');
      } on SocketException catch (e) {
        debugPrint('Erreur lors du ping de $apiUrl: $e');
      } catch (e) {
        debugPrint('Erreur lors du ping de $apiUrl: $e');
      }
    }
    
    debugPrint('Aucun serveur n\'a répondu au ping');
    
    // Si aucun serveur ne répond, activer le mode hors ligne
    setOfflineMode(true);
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
    // Si en mode hors ligne, simuler une erreur
    if (_offlineMode) {
      throw Exception('Vous êtes en mode hors ligne. Veuillez vous connecter à Internet pour vous inscrire.');
    }
    
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
        return true;
      } else {
        debugPrint('Échec de l\'inscription: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de l\'inscription: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('La requête a expiré après 30 secondes');
      throw Exception('Délai d\'attente dépassé lors de l\'inscription à $url');
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }
  
  // Fonction de connexion
  Future<ApiUser> login(String email, String password) async {
    // Si en mode hors ligne, vérifier les identifiants localement
    if (_offlineMode) {
      // Simulation de connexion hors ligne (à remplacer par une vraie vérification locale)
      if (email == 'test@dev700.com' && password == 'test123') {
        return ApiUser(
          id: 1,
          email: email,
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '0123456789',
          token: 'offline-token',
        );
      } else {
        throw Exception('Identifiants invalides en mode hors ligne');
      }
    }
    
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
        
        // Désactiver le mode hors ligne puisque la connexion fonctionne
        setOfflineMode(false);
        
        // La réponse contient un objet "user" et un "token" séparé
        final userData = data['user']; 
        final token = data['token'];
        
        return ApiUser(
          id: userData['id'] as int,
          email: userData['email'] as String,
          firstName: userData['firstName'] as String,
          lastName: userData['lastName'] as String,
          // Le phoneNumber peut être manquant dans la réponse de l'API
          phoneNumber: userData['phoneNumber'] ?? '0000000000',  // Valeur par défaut
          token: token,
        );
      } else {
        debugPrint('Échec de la connexion: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de la connexion: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('La requête a expiré après 30 secondes');
      throw Exception('Délai d\'attente dépassé lors de la connexion à $url');
    } on SocketException catch (e) {
      debugPrint('Erreur de connexion: $e');
      if (e.message.contains('No route to host')) {
        throw Exception('Impossible d\'accéder au serveur. Vérifiez votre connexion réseau.');
      } else if (e.message.contains('Connection refused')) {
        throw Exception('Le serveur refuse la connexion. Vérifiez que l\'API est bien en cours d\'exécution.');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      rethrow;
    }
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
} 
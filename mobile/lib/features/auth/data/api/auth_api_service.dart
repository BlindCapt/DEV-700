import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../domain/models/api_user.dart';

class AuthApiService {
  // URLs de base alternatives pour l'API
  static const String baseUrl = 'http://10.0.2.2:5094'; // Standard pour Android Emulator
  static const String alternativeUrl1 = 'http://10.101.53.231:5094'; // Adresse IP Wi-Fi réelle
  static const String alternativeUrl2 = 'http://192.168.132.1:5094'; // VMware
  static const String alternativeUrl3 = 'http://192.168.20.1:5094'; // VMware
  static const String alternativeUrl4 = 'http://192.168.0.1:5094'; // WSL
  
  // URL actuellement utilisée
  String _currentBaseUrl = alternativeUrl1; // Commencer avec l'adresse Wi-Fi directe
  
  // Endpoints
  static const String loginEndpoint = '/api/mobile/auth/login';
  static const String registerEndpoint = '/api/mobile/auth/register';
  static const String pingEndpoint = '/api/diagnostic/ping';

  // Client HTTP
  final http.Client _client;
  
  // Constructeur
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  // Méthode pour basculer vers l'URL alternative suivante
  void switchToNextUrl() {
    if (_currentBaseUrl == baseUrl) {
      _currentBaseUrl = alternativeUrl1;
      debugPrint('Basculé vers l\'URL alternative 1 (Wi-Fi): $_currentBaseUrl');
    } else if (_currentBaseUrl == alternativeUrl1) {
      _currentBaseUrl = alternativeUrl2;
      debugPrint('Basculé vers l\'URL alternative 2 (VMware): $_currentBaseUrl');
    } else if (_currentBaseUrl == alternativeUrl2) {
      _currentBaseUrl = alternativeUrl3;
      debugPrint('Basculé vers l\'URL alternative 3 (VMware): $_currentBaseUrl');
    } else if (_currentBaseUrl == alternativeUrl3) {
      _currentBaseUrl = alternativeUrl4;
      debugPrint('Basculé vers l\'URL alternative 4 (WSL): $_currentBaseUrl');
    } else {
      _currentBaseUrl = baseUrl;
      debugPrint('Revenu à l\'URL de base (Emulator): $_currentBaseUrl');
    }
  }

  // Méthode pour se connecter
  Future<ApiUser> login(String email, String password) async {
    try {
      final uri = Uri.parse('$_currentBaseUrl$loginEndpoint');
      debugPrint('Tentative de connexion à l\'URI: $uri');
      debugPrint('Avec les données: email=$email, password=***');
      
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30), // Augmenté à 30 secondes
        onTimeout: () {
          debugPrint('La requête a expiré après 30 secondes');
          throw Exception('Délai d\'attente dépassé lors de la connexion à $uri');
        },
      );

      debugPrint('Réponse du serveur: code=${response.statusCode}, body=${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('Données reçues: $data');
        
        // Combiner les données de l'utilisateur avec le token
        final userData = data['user'] as Map<String, dynamic>;
        userData['token'] = data['token'];
        
        return ApiUser.fromJson(userData);
      } else {
        throw Exception('Échec de connexion: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  // Méthode pour tester le ping avant toute connexion
  Future<bool> testPing() async {
    final allUrls = [alternativeUrl1, alternativeUrl2, alternativeUrl3, alternativeUrl4, baseUrl];
    
    for (final url in allUrls) {
      try {
        final pingUri = Uri.parse('$url$pingEndpoint');
        debugPrint('Test de ping avec: $pingUri');
        
        final response = await _client.get(
          pingUri,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Le ping a expiré après 5 secondes pour $url');
            return http.Response('{"error":"timeout"}', 408);
          },
        );

        if (response.statusCode == 200) {
          debugPrint('Ping réussi avec $url: ${response.body}');
          // Mettre à jour l'URL actuelle en cas de succès
          _currentBaseUrl = url;
          return true;
        } else {
          debugPrint('Échec du ping avec $url: Code ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Erreur lors du ping de $url: $e');
      }
    }
    
    return false;
  }

  // Méthode pour s'inscrire
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_currentBaseUrl$registerEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec d\'inscription: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  // Méthode pour tester la connectivité au serveur
  Future<bool> testConnectivity() async {
    for (final baseUrl in [baseUrl, alternativeUrl1, alternativeUrl2]) {
      try {
        debugPrint('Test de connectivité avec: $baseUrl/api/diagnostic/jwt-config');
        
        final response = await _client.get(
          Uri.parse('$baseUrl/api/diagnostic/jwt-config'),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Le test a expiré après 5 secondes pour $baseUrl');
            throw Exception('Délai d\'attente dépassé pour $baseUrl');
          },
        );

        if (response.statusCode == 200) {
          debugPrint('Connectivité réussie avec $baseUrl: ${response.body}');
          // Mettre à jour l'URL actuelle en cas de succès
          _currentBaseUrl = baseUrl;
          return true;
        } else {
          debugPrint('Échec avec $baseUrl: Code ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Erreur lors du test de $baseUrl: $e');
      }
    }
    return false;
  }
} 
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiUrlResolver {
  static const String _apiUrlKey = 'api_url';
  static const Duration _timeout = Duration(seconds: 2);
  
  // URL par défaut pour ngrok (à garder à jour lors des redémarrages de ngrok)
  static const String _defaultNgrokUrl = 'https://0335-163-5-3-101.ngrok-free.app';
  
  // Récupérer l'URL de l'API, sans détection automatique
  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiUrl = prefs.getString(_apiUrlKey);
    
    // Si l'URL est stockée, la retourner directement sans ping
    if (apiUrl != null) {
      debugPrint('Utilisation de l\'URL API stockée: $apiUrl');
      return apiUrl;
    }
    
    // Sinon, utiliser l'URL ngrok par défaut
    await _saveApiUrl(_defaultNgrokUrl);
    debugPrint('Utilisation de l\'URL ngrok par défaut: $_defaultNgrokUrl');
    return _defaultNgrokUrl;
  }
  
  // Définir manuellement l'URL de l'API
  Future<void> setApiUrl(String url) async {
    await _saveApiUrl(url);
  }
  
  // Enregistrer l'URL dans les préférences
  Future<void> _saveApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
    debugPrint('URL API enregistrée: $url');
  }
  
  // Tester si une URL est valide avec un ping - utilisé uniquement pour les tests manuels
  Future<bool> pingUrl(String baseUrl) async {
    try {
      final url = '$baseUrl/api/diagnostic/ping';
      debugPrint('Test de ping avec: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode == 200) {
        debugPrint('Ping réussi avec $baseUrl: ${response.body}');
        return true;
      }
      
      debugPrint('Ping échoué pour $baseUrl: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Le ping a expiré après ${_timeout.inSeconds} secondes pour $baseUrl');
      return false;
    }
  }
} 
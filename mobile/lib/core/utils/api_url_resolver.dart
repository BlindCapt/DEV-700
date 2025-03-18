import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiUrlResolver {
  static const String _apiUrlKey = 'api_url';
  static const Duration _timeout = Duration(seconds: 5);
  
  // URL par défaut pour ngrok (à remplacer par votre URL)
  static const String _defaultNgrokUrl = 'https://e348-2a04-cec2-a-b47f-546a-73c7-c44c-f63f.ngrok-free.app';
  
  // URL de développement locale
  static const String _localDevUrl = 'http://192.0.0.1:5094';
  
  // Récupérer l'URL de l'API, avec détection automatique si nécessaire
  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiUrl = prefs.getString(_apiUrlKey);
    
    // Si l'URL est stockée et valide, la retourner
    if (apiUrl != null) {
      // Vérifier que l'URL est toujours valide avec un ping
      if (await _pingUrl(apiUrl)) {
        return apiUrl;
      }
    }
    
    // Sinon, essayer de détecter automatiquement
    debugPrint('Tentative de détection automatique du serveur API...');
    
    // Essayer d'abord l'URL locale
    if (await _pingUrl(_localDevUrl)) {
      await _saveApiUrl(_localDevUrl);
      return _localDevUrl;
    }
    
    // Ensuite, essayer l'URL ngrok par défaut
    if (await _pingUrl(_defaultNgrokUrl)) {
      await _saveApiUrl(_defaultNgrokUrl);
      return _defaultNgrokUrl;
    }
    
    // Si toutes les tentatives échouent, retourner l'URL par défaut
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
  
  // Tester si une URL est valide avec un ping
  Future<bool> _pingUrl(String baseUrl) async {
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
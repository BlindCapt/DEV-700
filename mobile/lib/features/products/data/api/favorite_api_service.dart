import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/api_url_resolver.dart';
import '../../../auth/data/api/auth_api_service.dart';
import '../../domain/models/favorite.dart';

class FavoriteApiService {
  final AuthApiService _authService;
  final ApiUrlResolver _apiUrlResolver = ApiUrlResolver();

  FavoriteApiService(this._authService);

  // Obtenir tous les favoris de l'utilisateur
  Future<List<Favorite>> getUserFavorites() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final apiUrl = await _apiUrlResolver.getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/api/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Favorite.fromJson(json)).toList();
      } else {
        debugPrint('Erreur lors de la récupération des favoris: ${response.body}');
        throw Exception('Échec de la récupération des favoris: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception lors de la récupération des favoris: $e');
      throw Exception('Erreur: $e');
    }
  }

  // Vérifier si un produit est dans les favoris
  Future<bool> checkFavorite(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final apiUrl = await _apiUrlResolver.getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/api/favorites/check/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final bool isFavorite = json.decode(response.body);
        return isFavorite;
      } else {
        debugPrint('Erreur lors de la vérification du favori: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception lors de la vérification du favori: $e');
      return false;
    }
  }

  // Ajouter un produit aux favoris
  Future<bool> addToFavorites(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final apiUrl = await _apiUrlResolver.getApiUrl();
      final response = await http.post(
        Uri.parse('$apiUrl/api/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'productId': productId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Erreur lors de l\'ajout aux favoris: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  // Supprimer un produit des favoris
  Future<bool> removeFromFavorites(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final apiUrl = await _apiUrlResolver.getApiUrl();
      final response = await http.delete(
        Uri.parse('$apiUrl/api/favorites/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Erreur lors de la suppression du favori: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception lors de la suppression du favori: $e');
      return false;
    }
  }
} 
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';

/// Service pour gérer les appels API
class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Ajout d'intercepteurs pour le logging et le traitement des erreurs
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Ajouter un token d'authentification si disponible
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Méthode générique pour les requêtes GET
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Méthode générique pour les requêtes POST
  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Méthode générique pour les requêtes PUT
  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Méthode générique pour les requêtes DELETE
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Gestion des erreurs Dio
  void _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw Exception('Timeout de connexion, veuillez réessayer');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 401) {
          throw Exception('Non autorisé. Veuillez vous reconnecter.');
        } else if (statusCode == 404) {
          throw Exception('Ressource non trouvée');
        } else {
          final message = responseData is Map ? responseData['message'] : 'Erreur serveur';
          throw Exception(message ?? 'Erreur serveur inconnue');
        }
      
      case DioExceptionType.cancel:
        throw Exception('Requête annulée');
      
      default:
        throw Exception('Erreur de connexion: ${e.message}');
    }
  }
} 
import 'package:flutter/foundation.dart';

/// Modèle représentant un utilisateur mobile de l'API
class ApiUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? token;
  final DateTime? lastLogin;
  final bool isActive;

  ApiUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.token,
    this.lastLogin,
    this.isActive = true,
  });

  // Factory pour créer un utilisateur depuis un JSON
  factory ApiUser.fromJson(Map<String, dynamic> json) {
    try {
      return ApiUser(
        id: json['id'] as int,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        phoneNumber: json['phoneNumber'] as String? ?? '',
        token: json['token'] as String?,
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('Erreur lors de la conversion du JSON: $e');
      rethrow;
    }
  }

  // Convertir l'utilisateur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Pour afficher le nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';
} 
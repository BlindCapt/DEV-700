import 'package:flutter/foundation.dart';

/// Modèle représentant un utilisateur mobile de l'API
class ApiUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String token;

  ApiUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.token,
  });

  // Factory pour créer un utilisateur depuis un JSON
  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      token: json['token'] as String,
    );
  }

  // Convertir l'utilisateur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'token': token,
    };
  }

  // Pour afficher le nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  // Créer une copie avec des champs modifiés
  ApiUser copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? token,
  }) {
    return ApiUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
    );
  }
} 
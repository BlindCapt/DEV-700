/// Enum pour définir les rôles utilisateur
enum UserRole {
  customer,
  employee,
  manager,
}

/// Modèle représentant un utilisateur
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final DateTime? lastLogin;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.lastLogin,
    this.token,
  });

  // Factory pour créer un utilisateur depuis un JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Conversion de la chaîne de rôle en enum
    UserRole parseRole(String roleStr) {
      switch (roleStr.toLowerCase()) {
        case 'manager':
          return UserRole.manager;
        case 'employee':
          return UserRole.employee;
        case 'customer':
        default:
          return UserRole.customer;
      }
    }

    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: parseRole(json['role'] as String? ?? 'customer'),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      token: json['token'] as String?,
    );
  }

  // Convertir l'utilisateur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.toString().split('.').last,
      'lastLogin': lastLogin?.toIso8601String(),
      'token': token,
    };
  }

  // Copier l'utilisateur avec des valeurs modifiées
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    DateTime? lastLogin,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
      token: token ?? this.token,
    );
  }

  // Nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';
} 
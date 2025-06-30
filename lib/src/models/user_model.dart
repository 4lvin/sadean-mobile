// lib/src/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String role;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      role: json['role'] ?? 'member',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: $role}';
  }

  // Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  // Check if user is member
  bool get isMember => role.toLowerCase() == 'member';

  // Check if email is verified
  bool get isEmailVerified => emailVerifiedAt != null;

  // Get user initials for avatar
  String get initials {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  // Get display role
  String get displayRole {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'member':
        return 'Member';
      default:
        return role;
    }
  }
}
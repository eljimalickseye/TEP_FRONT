import 'gie.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role; // admin, driver, client
  final int? gieId;
  final Gie? gie;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.gieId,
    this.gie,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'client',
      gieId: json['gie_id'],
      gie: json['gie'] != null ? Gie.fromJson(json['gie']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'gie_id': gieId,
      'gie': gie?.toJson(),
    };
  }
}

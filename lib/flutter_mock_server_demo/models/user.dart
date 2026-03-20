class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'member') as String,
    );
  }

  User copyWith({String? name, String? email, String? role}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.role,
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final String? role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      role: json['role'] as String?,
    );
  }
}

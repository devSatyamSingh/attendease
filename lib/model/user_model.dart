
class UserModel {
  final int id;
  final String role; // "EMPLOYEE"
  final String name;

  const UserModel({
    required this.id,
    required this.role,
    required this.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    role: json['role'] as String,
    name: json['name'] as String,
  );
}
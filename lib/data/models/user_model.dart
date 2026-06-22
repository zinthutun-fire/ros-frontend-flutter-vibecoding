class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? kitchenId;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.kitchenId,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String,
      kitchenId: json['kitchen_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'kitchen_id': kitchenId,
      'is_active': isActive,
    };
  }
}

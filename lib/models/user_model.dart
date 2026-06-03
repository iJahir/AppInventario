class UserModel {
  final String? id;
  final String email;
  final String name;
  final String? username;
  final String? role;
  final String? profileImageUrl;

  UserModel({
    this.id,
    required this.email,
    required this.name,
    this.username,
    this.role,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      username: json['username'],
      role: json['role'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (username != null) 'username': username,
      'role': role,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? role,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}


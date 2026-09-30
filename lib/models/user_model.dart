class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? json['username'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: (json['role'] ?? '').toString().toUpperCase(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isActive': isActive,
    };
  }
}

class LoginResponse {
  final String token;
  final String role;
  final UserModel? user;

  LoginResponse({
    required this.token,
    required this.role,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      role: (json['role'] ?? '').toString().toUpperCase(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

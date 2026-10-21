class UserDto {
  final String id;
  final String username;
  final String email;
  final List<String> roles;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    var rawRoles = json['roles'];
    List<String> parsedRoles = [];
    if (rawRoles is List) {
      parsedRoles = rawRoles.map((r) => r.toString()).toList();
    } else if (rawRoles is String && rawRoles.isNotEmpty) {
      parsedRoles = [rawRoles];
    }

    return UserDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'roles': roles,
    };
  }

  String get primaryRole {
    if (roles.contains('Admin')) return 'Admin';
    if (roles.contains('Staff')) return 'Staff';
    if (roles.contains('Customer')) return 'Customer';
    return roles.isNotEmpty ? roles.first : 'User';
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String role;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class VerifyOtpRequest {
  final String username;
  final String otpCode;

  VerifyOtpRequest({
    required this.username,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'otpCode': otpCode,
    };
  }
}

class UpdateUserRequest {
  final String email;
  final String newRole;

  UpdateUserRequest({
    required this.email,
    required this.newRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'newRole': newRole,
    };
  }
}

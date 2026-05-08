// Mirror of: `apps/backend/src/auth/schemas.ts` (per ADR-0013)
// Field names and types must match the TypeBox shape 1:1. Update both sides
// in the same commit when the contract changes.

/// Mirror of: `UserSchema`
class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Mirror of: `RegisterRequestSchema`
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
  });

  final String email;
  final String password;
  final String name;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        if (phone != null) 'phone': phone,
      };
}

/// Mirror of: `RegisterResponseSchema`
class RegisterResponseDto {
  const RegisterResponseDto({required this.user});

  final AuthUserDto user;

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Mirror of: `LoginRequestSchema`
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Mirror of: `LoginResponseSchema` (TokensSchema + { user })
class LoginResponseDto {
  const LoginResponseDto({
    required this.access,
    required this.refresh,
    required this.user,
  });

  final String access;
  final String refresh;
  final AuthUserDto user;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Mirror of: `RefreshRequestSchema`
class RefreshRequestDto {
  const RefreshRequestDto({required this.refresh});

  final String refresh;

  Map<String, dynamic> toJson() => {'refresh': refresh};
}

/// Mirror of: `RefreshResponseSchema` (= TokensSchema)
class RefreshResponseDto {
  const RefreshResponseDto({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return RefreshResponseDto(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }
}

/// Mirror of: `MeResponseSchema`
class MeResponseDto {
  const MeResponseDto({required this.user});

  final AuthUserDto user;

  factory MeResponseDto.fromJson(Map<String, dynamic> json) {
    return MeResponseDto(
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Mirror of: `ErrorResponseSchema`
class AuthErrorDto {
  const AuthErrorDto({required this.error, required this.message});

  final String error;
  final String message;

  factory AuthErrorDto.fromJson(Map<String, dynamic> json) {
    return AuthErrorDto(
      error: json['error'] as String,
      message: json['message'] as String,
    );
  }
}

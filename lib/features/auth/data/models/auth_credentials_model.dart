import '../../domain/entities/auth_entities.dart';

/// Authentication credentials model
class AuthCredentialsModel extends AuthCredentials {
  const AuthCredentialsModel({
    required super.accessToken,
    required super.tokenType,
    required super.expiresIn,
    required super.refreshToken,
    super.idToken,
  });

  factory AuthCredentialsModel.fromJson(Map<String, dynamic> json) {
    return AuthCredentialsModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? json['expire_in'] as int? ?? 3600,
      refreshToken: json['refresh_token'] as String,
      idToken: json['id_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
      if (idToken != null) 'id_token': idToken,
    };
  }
}

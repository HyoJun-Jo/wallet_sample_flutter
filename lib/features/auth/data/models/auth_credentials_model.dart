import '../../../../core/auth/entities/auth_entities.dart';

class AuthCredentialsModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String refreshToken;
  final String? idToken;

  const AuthCredentialsModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
    this.idToken,
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

  AuthCredentials toEntity() {
    return AuthCredentials(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      refreshToken: refreshToken,
      idToken: idToken,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Login type (email or SNS providers)
enum LoginType {
  email,
  google,
  apple,
  kakao,
  naver,
  line,
}

/// Email Login Result - Sealed class for business logic branching
sealed class EmailLoginResult extends Equatable {
  const EmailLoginResult();
}

/// Email Login successful - credentials issued
class EmailLoginSuccess extends EmailLoginResult {
  final AuthCredentials credentials;

  const EmailLoginSuccess({required this.credentials});

  @override
  List<Object?> get props => [credentials];
}

/// Email Login - user not registered (code 602)
class EmailUserNotRegistered extends EmailLoginResult {
  final String email;

  const EmailUserNotRegistered({required this.email});

  @override
  List<Object?> get props => [email];
}

/// SNS Login Result - Sealed class for business logic branching
sealed class SnsLoginResult extends Equatable {
  const SnsLoginResult();
}

/// SNS Login successful - credentials issued
class SnsLoginSuccess extends SnsLoginResult {
  final AuthCredentials credentials;
  final String? snsEmail;

  const SnsLoginSuccess({required this.credentials, this.snsEmail});

  @override
  List<Object?> get props => [credentials, snsEmail];
}

/// SNS Login - user not found in system (code 618)
class SnsUserNotFound extends SnsLoginResult {
  final String email;
  final String token;
  final String sixcode;
  final String language;
  final int timeout;

  const SnsUserNotFound({
    required this.email,
    required this.token,
    required this.sixcode,
    required this.language,
    required this.timeout,
  });

  @override
  List<Object?> get props => [email, token, sixcode, language, timeout];
}

class SnsAuthResult extends Equatable {
  final String token;
  final String? email;

  const SnsAuthResult({required this.token, this.email});

  @override
  List<Object?> get props => [token, email];
}

class AuthCredentials extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String refreshToken;
  final String? idToken;

  const AuthCredentials({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
    this.idToken,
  });

  @override
  List<Object?> get props => [
        accessToken,
        tokenType,
        expiresIn,
        refreshToken,
        idToken,
      ];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entities.dart';

/// Login event base class
sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Email login request
class LoginWithEmailRequested extends LoginEvent {
  final String email;
  final String password;
  final bool autoLogin;

  const LoginWithEmailRequested({
    required this.email,
    required this.password,
    this.autoLogin = false,
  });

  @override
  List<Object?> get props => [email, password, autoLogin];
}

/// SNS token login request
class LoginWithSnsRequested extends LoginEvent {
  final String snsToken;
  final LoginType loginType;
  final bool autoLogin;
  final String? snsEmail;

  const LoginWithSnsRequested({
    required this.snsToken,
    required this.loginType,
    this.autoLogin = false,
    this.snsEmail,
  });

  @override
  List<Object?> get props => [snsToken, loginType, autoLogin, snsEmail];
}

/// Auto login request (on app start)
class AutoLoginRequested extends LoginEvent {
  const AutoLoginRequested();
}

/// Token refresh request
class TokenRefreshRequested extends LoginEvent {
  const TokenRefreshRequested();
}

/// Logout request
class LogoutRequested extends LoginEvent {
  const LogoutRequested();
}

/// Authentication check request
class LoginCheckRequested extends LoginEvent {
  const LoginCheckRequested();
}

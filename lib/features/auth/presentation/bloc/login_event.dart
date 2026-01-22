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

/// SNS sign-in request (OAuth + API in one flow)
class SnsSignInRequested extends LoginEvent {
  final LoginType loginType;
  final bool autoLogin;

  const SnsSignInRequested({
    required this.loginType,
    this.autoLogin = false,
  });

  @override
  List<Object?> get props => [loginType, autoLogin];
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

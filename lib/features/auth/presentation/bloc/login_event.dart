import 'package:equatable/equatable.dart';
import '../../../../core/auth/entities/auth_entities.dart';

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
/// SNS OAuth SDK handles session persistence automatically
class SnsSignInRequested extends LoginEvent {
  final LoginType loginType;

  const SnsSignInRequested({
    required this.loginType,
  });

  @override
  List<Object?> get props => [loginType];
}

/// Token refresh request
class TokenRefreshRequested extends LoginEvent {
  const TokenRefreshRequested();
}

/// Logout request
class LogoutRequested extends LoginEvent {
  const LogoutRequested();
}

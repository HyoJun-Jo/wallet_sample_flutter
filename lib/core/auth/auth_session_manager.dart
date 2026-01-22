import 'package:flutter/foundation.dart';

/// Authentication status
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

/// Manages authentication session state across the app
/// Used by AuthInterceptor to notify session expiration
/// Extends ChangeNotifier for GoRouter refreshListenable integration
class AuthSessionManager extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;

  /// Current authentication status
  AuthStatus get status => _status;

  /// Whether user is authenticated
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Called when session expires (refresh token invalid)
  void onSessionExpired() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called when user successfully authenticates
  void onAuthenticated() {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Called on logout
  void onLogout() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Reset to unknown state (e.g., app start)
  void reset() {
    _status = AuthStatus.unknown;
    notifyListeners();
  }
}

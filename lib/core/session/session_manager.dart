import 'package:flutter/foundation.dart';

import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

/// Initial route after app startup check
enum InitialRoute {
  login,
  walletCreate,
  main,
}

class SessionManager extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthStatus _status = AuthStatus.unknown;
  InitialRoute? _initialRoute;
  bool _isInitialized = false;

  SessionManager({
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage;

  AuthStatus get status => _status;
  InitialRoute? get initialRoute => _initialRoute;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize app and determine initial route
  /// Note: Wallet check is done separately by WalletRepository
  Future<void> initialize({bool hasWallet = false}) async {
    if (_isInitialized) return;

    // Check if access token exists
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      _status = AuthStatus.unauthenticated;
      _initialRoute = InitialRoute.login;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // Check if auto login is enabled
    final autoLogin = _localStorage.getBool(LocalStorageKeys.autoLogin) ?? false;

    if (!autoLogin) {
      _status = AuthStatus.unauthenticated;
      _initialRoute = InitialRoute.login;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // Authenticated - route based on wallet existence
    _status = AuthStatus.authenticated;
    _initialRoute = hasWallet ? InitialRoute.main : InitialRoute.walletCreate;

    _isInitialized = true;
    notifyListeners();
  }

  void onAuthenticated() {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void onSessionExpired() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    await _localStorage.clear();
    _status = AuthStatus.unauthenticated;
    _initialRoute = InitialRoute.login;
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.unknown;
    _initialRoute = null;
    _isInitialized = false;
    notifyListeners();
  }
}

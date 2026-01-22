import 'package:flutter/foundation.dart';

import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class SessionManager extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthStatus _status = AuthStatus.unknown;

  SessionManager({
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage;

  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

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
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.unknown;
    notifyListeners();
  }
}

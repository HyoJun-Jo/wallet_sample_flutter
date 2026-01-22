import 'package:shared_preferences/shared_preferences.dart';

/// Local Storage keys
class LocalStorageKeys {
  LocalStorageKeys._();

  static const String isLoggedIn = 'is_logged_in';
  static const String selectedNetwork = 'selected_network';
  static const String userEmail = 'user_email';
  static const String loginType = 'login_type';
  static const String autoLogin = 'auto_login';
}

/// Local Storage service
class LocalStorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('LocalStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _preferences.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences.getInt(key);
  }

  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }

  Future<void> clear() async {
    await _preferences.clear();
  }
}

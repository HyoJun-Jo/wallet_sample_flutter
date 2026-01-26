import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/token_info_model.dart';

/// Token Local DataSource interface for caching
abstract class TokenLocalDataSource {
  /// Get cached tokens for a wallet address
  Future<List<TokenInfoModel>?> getCachedTokens(String walletAddress);

  /// Cache tokens for a wallet address
  Future<void> cacheTokens(String walletAddress, List<TokenInfoModel> tokens);

  /// Clear cached tokens for a wallet address
  Future<void> clearCachedTokens(String walletAddress);

  /// Clear all cached tokens
  Future<void> clearAllCachedTokens();
}

/// Token Local DataSource implementation using SharedPreferences
class TokenLocalDataSourceImpl implements TokenLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cachePrefix = 'cached_tokens_';
  static const String _cacheKeysKey = 'cached_tokens_keys';

  TokenLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<List<TokenInfoModel>?> getCachedTokens(String walletAddress) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    final jsonString = _prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => TokenInfoModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, clear the corrupted cache
      await clearCachedTokens(walletAddress);
      return null;
    }
  }

  @override
  Future<void> cacheTokens(String walletAddress, List<TokenInfoModel> tokens) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    final jsonList = tokens.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await _prefs.setString(key, jsonString);

    // Track cached keys for cleanup
    await _addCacheKey(walletAddress);
  }

  @override
  Future<void> clearCachedTokens(String walletAddress) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    await _prefs.remove(key);
    await _removeCacheKey(walletAddress);
  }

  @override
  Future<void> clearAllCachedTokens() async {
    final keys = _getCacheKeys();
    for (final address in keys) {
      final key = '$_cachePrefix${address.toLowerCase()}';
      await _prefs.remove(key);
    }
    await _prefs.remove(_cacheKeysKey);
  }

  List<String> _getCacheKeys() {
    return _prefs.getStringList(_cacheKeysKey) ?? [];
  }

  Future<void> _addCacheKey(String walletAddress) async {
    final keys = _getCacheKeys();
    final normalizedAddress = walletAddress.toLowerCase();
    if (!keys.contains(normalizedAddress)) {
      keys.add(normalizedAddress);
      await _prefs.setStringList(_cacheKeysKey, keys);
    }
  }

  Future<void> _removeCacheKey(String walletAddress) async {
    final keys = _getCacheKeys();
    keys.remove(walletAddress.toLowerCase());
    await _prefs.setStringList(_cacheKeysKey, keys);
  }
}

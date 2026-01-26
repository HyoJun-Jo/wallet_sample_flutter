import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_model.dart';

abstract class HistoryLocalDataSource {
  Future<List<HistoryModel>?> getCachedHistory(String walletAddress);

  Future<void> cacheHistory(
    String walletAddress,
    List<HistoryModel> entries,
  );

  Future<void> clearCachedHistory(String walletAddress);

  Future<void> clearAllCachedHistory();
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cachePrefix = 'cached_history_';
  static const String _cacheKeysKey = 'cached_history_keys';

  HistoryLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<List<HistoryModel>?> getCachedHistory(
    String walletAddress,
  ) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    final jsonString = _prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => HistoryModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await clearCachedHistory(walletAddress);
      return null;
    }
  }

  @override
  Future<void> cacheHistory(
    String walletAddress,
    List<HistoryModel> entries,
  ) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    final jsonList = entries.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await _prefs.setString(key, jsonString);
    await _addCacheKey(walletAddress);
  }

  @override
  Future<void> clearCachedHistory(String walletAddress) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    await _prefs.remove(key);
    await _removeCacheKey(walletAddress);
  }

  @override
  Future<void> clearAllCachedHistory() async {
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

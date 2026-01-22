import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_history_model.dart';

/// History Local DataSource interface for caching
abstract class HistoryLocalDataSource {
  /// Get cached transactions for a wallet address
  Future<List<TransactionHistoryModel>?> getCachedTransactions(String walletAddress);

  /// Cache transactions for a wallet address
  Future<void> cacheTransactions(
    String walletAddress,
    List<TransactionHistoryModel> transactions,
  );

  /// Clear cached transactions for a wallet address
  Future<void> clearCachedTransactions(String walletAddress);

  /// Clear all cached transactions
  Future<void> clearAllCachedTransactions();
}

/// History Local DataSource implementation using SharedPreferences
class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cachePrefix = 'cached_history_';
  static const String _cacheKeysKey = 'cached_history_keys';

  HistoryLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<List<TransactionHistoryModel>?> getCachedTransactions(
    String walletAddress,
  ) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    final jsonString = _prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => TransactionHistoryModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, clear the corrupted cache
      await clearCachedTransactions(walletAddress);
      return null;
    }
  }

  @override
  Future<void> cacheTransactions(
    String walletAddress,
    List<TransactionHistoryModel> transactions,
  ) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    final jsonList = transactions.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await _prefs.setString(key, jsonString);

    // Track cached keys for cleanup
    await _addCacheKey(walletAddress);
  }

  @override
  Future<void> clearCachedTransactions(String walletAddress) async {
    final key = '$_cachePrefix${walletAddress.toLowerCase()}';
    await _prefs.remove(key);
    await _removeCacheKey(walletAddress);
  }

  @override
  Future<void> clearAllCachedTransactions() async {
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

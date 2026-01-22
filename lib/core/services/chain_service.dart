import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/chain.dart';

/// Service for loading and managing chain configurations
class ChainService {
  List<Chain> _chains = [];
  bool _isLoaded = false;

  /// Load chains from assets/chains.json
  Future<void> loadChains() async {
    if (_isLoaded) return;

    final jsonString = await rootBundle.loadString('assets/chains.json');
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final chainsList = data['chains'] as List<dynamic>;

    _chains = chainsList
        .map((e) => Chain.fromJson(e as Map<String, dynamic>))
        .toList();
    _isLoaded = true;
  }

  /// Get all chains
  List<Chain> get chains => List.unmodifiable(_chains);

  /// Get mainnet chains only
  List<Chain> get mainnetChains =>
      _chains.where((c) => c.isMainnet).toList();

  /// Get testnet chains only
  List<Chain> get testnetChains =>
      _chains.where((c) => c.isTestnet).toList();

  /// Get chain by network name
  Chain? getByNetwork(String network) {
    try {
      return _chains.firstWhere((c) => c.network == network);
    } catch (_) {
      return null;
    }
  }

  /// Get chain by chainId
  Chain? getByChainId(int chainId) {
    try {
      return _chains.firstWhere((c) => c.chainId == chainId);
    } catch (_) {
      return null;
    }
  }

  /// Get chain by coin symbol
  Chain? getByCoin(String coin) {
    try {
      return _chains.firstWhere((c) => c.coin.toLowerCase() == coin.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Check if chains are loaded
  bool get isLoaded => _isLoaded;

  /// Get EVM mainnet network names as comma-separated string
  /// e.g., "ethereum,polygon,binance,arbitrum,avalanche,kaia"
  String get evmMainnetNetworks {
    return mainnetChains
        .where((c) => c.type == 'mainnet') // Only mainnet EVM chains
        .map((c) => c.network)
        .join(',');
  }

  /// Get all mainnet network names as comma-separated string
  String get allMainnetNetworks {
    return mainnetChains.map((c) => c.network).join(',');
  }

  /// Get EVM mainnet + testnet network names as comma-separated string
  /// For development/testing purposes
  String get evmAllNetworks {
    return _chains
        .where((c) => c.type == 'mainnet' || c.type == 'testnet')
        .map((c) => c.network)
        .join(',');
  }

  /// Get all network names (mainnet + testnet) as comma-separated string
  String get allNetworks {
    return _chains.map((c) => c.network).join(',');
  }
}

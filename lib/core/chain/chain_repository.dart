import 'dart:convert';

import 'package:flutter/services.dart';

import 'chain.dart';

abstract class ChainRepository {
  List<Chain> get chains;
  List<Chain> get mainnetChains;
  List<Chain> get testnetChains;
  Chain? getByNetwork(String network);
  Chain? getByChainId(int chainId);
  Chain? getByCoin(String coin);
  String get mainnetNetworks;
  String get allNetworks;
  Future<void> load();
}

class ChainRepositoryImpl implements ChainRepository {
  List<Chain> _chains = [];
  bool _isLoaded = false;

  @override
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/chains.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final chainsList = data['chains'] as List<dynamic>;

      _chains = chainsList
          .map((e) => Chain.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      _chains = [];
      _isLoaded = false;
      rethrow;
    }
  }

  @override
  List<Chain> get chains => List.unmodifiable(_chains);

  @override
  List<Chain> get mainnetChains => _chains.where((c) => c.isMainnet).toList();

  @override
  List<Chain> get testnetChains => _chains.where((c) => c.isTestnet).toList();

  @override
  Chain? getByNetwork(String network) {
    try {
      return _chains.firstWhere((c) => c.network == network);
    } catch (_) {
      return null;
    }
  }

  @override
  Chain? getByChainId(int chainId) {
    try {
      return _chains.firstWhere((c) => c.chainId == chainId);
    } catch (_) {
      return null;
    }
  }

  @override
  Chain? getByCoin(String coin) {
    try {
      return _chains.firstWhere(
        (c) => c.coin.toLowerCase() == coin.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String get mainnetNetworks => mainnetChains.map((c) => c.network).join(',');

  @override
  String get allNetworks => _chains.map((c) => c.network).join(',');
}

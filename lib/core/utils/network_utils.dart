import 'package:flutter/material.dart';

/// Utility class for network/chain display operations
class NetworkUtils {
  NetworkUtils._();

  /// Network display names mapping
  static const Map<String, String> _displayNames = {
    'ethereum': 'ETH',
    'binance': 'BSC',
    'polygon': 'MATIC',
    'arbitrum': 'ARB',
    'avalanche': 'AVAX',
    'kaia': 'KAIA',
    'optimism': 'OP',
    'base': 'BASE',
    'fantom': 'FTM',
    'cronos': 'CRO',
    'gnosis': 'GNO',
    'solana': 'SOL',
  };

  /// Network colors mapping
  static const Map<String, Color> _colors = {
    'ethereum': Color(0xFF627EEA),
    'binance': Color(0xFFF3BA2F),
    'polygon': Color(0xFF8247E5),
    'arbitrum': Color(0xFF28A0F0),
    'avalanche': Color(0xFFE84142),
    'kaia': Color(0xFF00A29A),
    'optimism': Color(0xFFFF0420),
    'base': Color(0xFF0052FF),
    'fantom': Color(0xFF1969FF),
    'cronos': Color(0xFF002D74),
    'gnosis': Color(0xFF04795B),
    'solana': Color(0xFF9945FF),
  };

  /// Get display name for network
  /// e.g., "ethereum" → "ETH", "binance" → "BSC"
  static String getDisplayName(String network) {
    final key = network.toLowerCase();
    return _displayNames[key] ?? network.toUpperCase().substring(0, 3.clamp(0, network.length));
  }

  /// Get color for network
  static Color getColor(String network) {
    final key = network.toLowerCase();
    return _colors[key] ?? Colors.grey;
  }

  /// Get explorer URL for network
  static String? getExplorerUrl(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'https://etherscan.io';
      case 'binance':
        return 'https://bscscan.com';
      case 'polygon':
        return 'https://polygonscan.com';
      case 'arbitrum':
        return 'https://arbiscan.io';
      case 'avalanche':
        return 'https://snowtrace.io';
      case 'kaia':
        return 'https://kaiascan.io';
      case 'optimism':
        return 'https://optimistic.etherscan.io';
      case 'base':
        return 'https://basescan.org';
      case 'solana':
        return 'https://solscan.io';
      default:
        return null;
    }
  }

  /// Get transaction explorer URL
  static String? getTxUrl(String network, String txHash) {
    final baseUrl = getExplorerUrl(network);
    if (baseUrl == null) return null;

    if (network.toLowerCase() == 'solana') {
      return '$baseUrl/tx/$txHash';
    }
    return '$baseUrl/tx/$txHash';
  }

  /// Get address explorer URL
  static String? getAddressUrl(String network, String address) {
    final baseUrl = getExplorerUrl(network);
    if (baseUrl == null) return null;

    if (network.toLowerCase() == 'solana') {
      return '$baseUrl/account/$address';
    }
    return '$baseUrl/address/$address';
  }

  /// Check if network is EVM compatible
  static bool isEvmNetwork(String network) {
    const evmNetworks = {
      'ethereum', 'binance', 'polygon', 'arbitrum', 'avalanche',
      'kaia', 'optimism', 'base', 'fantom', 'cronos', 'gnosis',
    };
    return evmNetworks.contains(network.toLowerCase());
  }
}

import '../constants/networks.dart';

/// Utility class for blockchain network operations
/// Delegates to Networks class for consistency
class NetworkUtils {
  NetworkUtils._();

  /// Format network identifier to display name
  static String formatDisplayName(String network) {
    final config = Networks.getConfig(network);
    if (config != null) {
      return config.name;
    }

    // Fallback: Capitalize first letter
    if (network.isEmpty) return network;
    return network[0].toUpperCase() + network.substring(1);
  }

  /// Get network icon URL
  static String? getIconUrl(String network) {
    return Networks.getIcon(network);
  }

  /// Get network icon asset path (local assets)
  static String? getIconPath(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
      case 'ethereum_sepolia':
        return 'assets/icons/networks/ethereum.png';
      case 'polygon':
      case 'polygon_amoy':
        return 'assets/icons/networks/polygon.png';
      case 'binance':
      case 'binance_testnet':
        return 'assets/icons/networks/bsc.png';
      case 'arbitrum':
      case 'arbitrum_sepolia':
        return 'assets/icons/networks/arbitrum.png';
      case 'avalanche':
      case 'avalanche_fuji':
        return 'assets/icons/networks/avalanche.png';
      case 'kaia':
      case 'kaia_kairos':
        return 'assets/icons/networks/kaia.png';
      case 'solana':
      case 'solana_devnet':
        return 'assets/icons/networks/solana.png';
      case 'bitcoin':
      case 'bitcoin_testnet':
        return 'assets/icons/networks/bitcoin.png';
      default:
        return null;
    }
  }

  /// Check if network is EVM compatible
  static bool isEvmNetwork(String network) {
    return Networks.isEvmNetwork(network);
  }

  /// Check if network is Bitcoin
  static bool isBitcoinNetwork(String network) {
    return Networks.isBitcoinNetwork(network);
  }

  /// Check if network is Solana
  static bool isSolanaNetwork(String network) {
    return Networks.isSolanaNetwork(network);
  }

  /// Get network symbol
  static String getSymbol(String network) {
    return Networks.getSymbol(network);
  }

  /// Get transaction explorer URL
  static String? getTransactionUrl(String network, String hash) {
    return Networks.getTransactionUrl(network, hash);
  }
}

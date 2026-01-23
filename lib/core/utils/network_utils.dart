/// Utility class for blockchain network operations
class NetworkUtils {
  NetworkUtils._();

  /// Format network identifier to display name
  static String formatDisplayName(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'Ethereum';
      case 'polygon':
        return 'Polygon';
      case 'binance':
      case 'bsc':
        return 'BNB Chain';
      case 'arbitrum':
        return 'Arbitrum';
      case 'optimism':
        return 'Optimism';
      case 'avalanche':
        return 'Avalanche';
      case 'kaia':
        return 'Kaia';
      case 'kaia_kairos':
        return 'Kaia Kairos';
      case 'solana':
        return 'Solana';
      case 'bitcoin':
        return 'Bitcoin';
      default:
        // Capitalize first letter
        if (network.isEmpty) return network;
        return network[0].toUpperCase() + network.substring(1);
    }
  }

  /// Get network icon asset path (if available)
  static String? getIconPath(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'assets/icons/networks/ethereum.png';
      case 'polygon':
        return 'assets/icons/networks/polygon.png';
      case 'binance':
      case 'bsc':
        return 'assets/icons/networks/bsc.png';
      case 'arbitrum':
        return 'assets/icons/networks/arbitrum.png';
      case 'optimism':
        return 'assets/icons/networks/optimism.png';
      case 'avalanche':
        return 'assets/icons/networks/avalanche.png';
      case 'kaia':
      case 'kaia_kairos':
        return 'assets/icons/networks/kaia.png';
      case 'solana':
        return 'assets/icons/networks/solana.png';
      case 'bitcoin':
        return 'assets/icons/networks/bitcoin.png';
      default:
        return null;
    }
  }

  /// Check if network is EVM compatible
  static bool isEvmNetwork(String network) {
    const evmNetworks = [
      'ethereum',
      'polygon',
      'binance',
      'bsc',
      'arbitrum',
      'optimism',
      'avalanche',
      'kaia',
      'kaia_kairos',
    ];
    return evmNetworks.contains(network.toLowerCase());
  }
}

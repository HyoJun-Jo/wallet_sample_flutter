/// ABC Network enum
///
/// Network types supported by ABC Wallet.
/// Maps chain IDs to network names.
/// Reference: talken-mfe-flutter AbcNetwork
enum AbcNetwork {
  all(-1, false, 'all'),
  arbitrum(42161, true, 'arbitrum'),
  arbitrumSepolia(421614, false, 'arbitrum_sepolia'),
  ethereum(1, true, 'ethereum'),
  ethereumSepolia(11155111, false, 'ethereum_sepolia'),
  kaia(8217, true, 'kaia'),
  kaiaKairos(1001, false, 'kaia_kairos'),
  binance(56, true, 'binance'),
  binanceTestnet(97, false, 'binance_testnet'),
  polygon(137, true, 'polygon'),
  polygonAmoy(80002, false, 'polygon_amoy'),
  avalanche(43114, true, 'avalanche'),
  avalancheFuji(43113, false, 'avalanche_fuji'),
  mantle(5000, true, 'mantle'),
  mantleSepolia(5003, false, 'mantle_sepolia'),
  chainbounty(51828, true, 'chainbounty'),
  chainbountyTestnet(56580, false, 'chainbounty_testnet');

  final int chainId;
  final bool mainnet;
  final String value;

  const AbcNetwork(this.chainId, this.mainnet, this.value);

  /// Get network by chain ID
  static AbcNetwork? chainOf(int chainId) {
    try {
      return values.firstWhere((network) => network.chainId == chainId);
    } catch (e) {
      return null;
    }
  }

  /// Get network by name
  static AbcNetwork? nameOf(String name) {
    try {
      return values.firstWhere(
        (network) => network.value == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all mainnet networks
  static List<AbcNetwork> get mainnetNetworks {
    return values.where((network) => network.mainnet).toList();
  }

  /// Get all testnet networks
  static List<AbcNetwork> get testnetNetworks {
    return values.where((network) => !network.mainnet && network != all).toList();
  }

  /// Get display name for the network
  String get displayName {
    switch (this) {
      case AbcNetwork.all:
        return 'All Networks';
      case AbcNetwork.ethereum:
        return 'Ethereum';
      case AbcNetwork.ethereumSepolia:
        return 'Ethereum Sepolia';
      case AbcNetwork.polygon:
        return 'Polygon';
      case AbcNetwork.polygonAmoy:
        return 'Polygon Amoy';
      case AbcNetwork.binance:
        return 'BNB Smart Chain';
      case AbcNetwork.binanceTestnet:
        return 'BSC Testnet';
      case AbcNetwork.arbitrum:
        return 'Arbitrum One';
      case AbcNetwork.arbitrumSepolia:
        return 'Arbitrum Sepolia';
      case AbcNetwork.avalanche:
        return 'Avalanche C-Chain';
      case AbcNetwork.avalancheFuji:
        return 'Avalanche Fuji';
      case AbcNetwork.kaia:
        return 'Kaia';
      case AbcNetwork.kaiaKairos:
        return 'Kaia Kairos';
      case AbcNetwork.mantle:
        return 'Mantle';
      case AbcNetwork.mantleSepolia:
        return 'Mantle Sepolia';
      case AbcNetwork.chainbounty:
        return 'Chainbounty';
      case AbcNetwork.chainbountyTestnet:
        return 'Chainbounty Testnet';
    }
  }

  /// Get native token symbol for the network
  String get nativeSymbol {
    switch (this) {
      case AbcNetwork.ethereum:
      case AbcNetwork.ethereumSepolia:
      case AbcNetwork.arbitrum:
      case AbcNetwork.arbitrumSepolia:
        return 'ETH';
      case AbcNetwork.polygon:
      case AbcNetwork.polygonAmoy:
        return 'POL';
      case AbcNetwork.binance:
      case AbcNetwork.binanceTestnet:
        return 'BNB';
      case AbcNetwork.avalanche:
      case AbcNetwork.avalancheFuji:
        return 'AVAX';
      case AbcNetwork.kaia:
      case AbcNetwork.kaiaKairos:
        return 'KAIA';
      case AbcNetwork.mantle:
      case AbcNetwork.mantleSepolia:
        return 'MNT';
      case AbcNetwork.chainbounty:
      case AbcNetwork.chainbountyTestnet:
        return 'CBT';
      case AbcNetwork.all:
        return '';
    }
  }
}

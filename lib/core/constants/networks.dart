// Network configuration constants

/// Network type
enum NetworkType { mainnet, testnet }

/// Network configuration model
class NetworkConfig {
  final String name;
  final String coin;
  final String symbol;
  final int chainId;
  final String network;
  final int decimals;
  final String coingeckoId;
  final String icon;
  final NetworkType type;
  final String rpcUrl;
  final String explorerUrl;
  final String transactionUrl;

  const NetworkConfig({
    required this.name,
    required this.coin,
    required this.symbol,
    required this.chainId,
    required this.network,
    required this.decimals,
    required this.coingeckoId,
    required this.icon,
    required this.type,
    required this.rpcUrl,
    required this.explorerUrl,
    required this.transactionUrl,
  });

  bool get isMainnet => type == NetworkType.mainnet;
  bool get isTestnet => type == NetworkType.testnet;
}

/// All network configurations
class Networks {
  Networks._();

  static const Map<String, NetworkConfig> configs = {
    // Solana
    'solana': NetworkConfig(
      name: 'Solana',
      coin: 'sol',
      symbol: 'SOL',
      chainId: 0,
      network: 'solana',
      decimals: 9,
      coingeckoId: 'solana',
      icon: 'https://coin-images.coingecko.com/coins/images/4128/standard/solana.png?1718769756',
      type: NetworkType.mainnet,
      rpcUrl: 'https://api.mainnet-beta.solana.com',
      explorerUrl: 'https://solscan.io/',
      transactionUrl: 'https://solscan.io/tx/',
    ),
    'solana_devnet': NetworkConfig(
      name: 'Solana Devnet',
      coin: 'sol',
      symbol: 'SOL',
      chainId: 0,
      network: 'solana_devnet',
      decimals: 9,
      coingeckoId: 'solana',
      icon: 'https://coin-images.coingecko.com/coins/images/4128/standard/solana.png?1718769756',
      type: NetworkType.testnet,
      rpcUrl: 'https://api.devnet.solana.com',
      explorerUrl: 'https://solscan.io/?cluster=devnet/',
      transactionUrl: 'https://solscan.io/tx/',
    ),

    // Bitcoin
    'bitcoin': NetworkConfig(
      name: 'Bitcoin',
      coin: 'btc',
      symbol: 'BTC',
      chainId: 0,
      network: 'bitcoin',
      decimals: 8,
      coingeckoId: 'bitcoin',
      icon: 'https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png?1696501400',
      type: NetworkType.mainnet,
      rpcUrl: 'https://bitcoin.drpc.org/',
      explorerUrl: 'https://www.oklink.com/btc',
      transactionUrl: 'https://www.oklink.com/btc/tx/',
    ),
    'bitcoin_testnet': NetworkConfig(
      name: 'Bitcoin Testnet',
      coin: 'btc',
      symbol: 'BTC',
      chainId: 0,
      network: 'bitcoin_testnet',
      decimals: 8,
      coingeckoId: 'bitcoin',
      icon: 'https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png?1696501400',
      type: NetworkType.testnet,
      rpcUrl: 'https://bitcoin-testnet.drpc.org/',
      explorerUrl: 'https://blockstream.info/testnet',
      transactionUrl: 'https://blockstream.info/testnet/tx/',
    ),

    // Ethereum
    'ethereum': NetworkConfig(
      name: 'Ethereum',
      coin: 'eth',
      symbol: 'ETH',
      chainId: 1,
      network: 'ethereum',
      decimals: 18,
      coingeckoId: 'ethereum',
      icon: 'https://coin-images.coingecko.com/coins/images/279/large/ethereum.png?1696501628',
      type: NetworkType.mainnet,
      rpcUrl: 'https://mainnet.infura.io/v3/',
      explorerUrl: 'https://etherscan.io',
      transactionUrl: 'https://etherscan.io/tx/',
    ),
    'ethereum_sepolia': NetworkConfig(
      name: 'Ethereum Sepolia',
      coin: 'eth',
      symbol: 'ETH',
      chainId: 11155111,
      network: 'ethereum_sepolia',
      decimals: 18,
      coingeckoId: 'ethereum',
      icon: 'https://coin-images.coingecko.com/coins/images/279/large/ethereum.png?1696501628',
      type: NetworkType.testnet,
      rpcUrl: 'https://rpc.sepolia.org',
      explorerUrl: 'https://sepolia.etherscan.io',
      transactionUrl: 'https://sepolia.etherscan.io/tx/',
    ),

    // BNB Chain
    'binance': NetworkConfig(
      name: 'BNB Chain',
      coin: 'bnb',
      symbol: 'BNB',
      chainId: 56,
      network: 'binance',
      decimals: 18,
      coingeckoId: 'binancecoin',
      icon: 'https://coin-images.coingecko.com/coins/images/825/large/bnb-icon2_2x.png?1696501970',
      type: NetworkType.mainnet,
      rpcUrl: 'https://bnb-mainnet.nodit.io/',
      explorerUrl: 'https://bscscan.com',
      transactionUrl: 'https://bscscan.com/tx/',
    ),
    'binance_testnet': NetworkConfig(
      name: 'BNB Chain Testnet',
      coin: 'tbnb',
      symbol: 'tBNB',
      chainId: 97,
      network: 'binance_testnet',
      decimals: 18,
      coingeckoId: 'binancecoin',
      icon: 'https://coin-images.coingecko.com/coins/images/825/large/bnb-icon2_2x.png?1696501970',
      type: NetworkType.testnet,
      rpcUrl: 'https://data-seed-prebsc-1-s1.bnbchain.org:8545',
      explorerUrl: 'https://testnet.bscscan.com',
      transactionUrl: 'https://testnet.bscscan.com/tx/',
    ),

    // Polygon
    'polygon': NetworkConfig(
      name: 'Polygon',
      coin: 'matic',
      symbol: 'POL',
      chainId: 137,
      network: 'polygon',
      decimals: 18,
      coingeckoId: 'matic-network',
      icon: 'https://coin-images.coingecko.com/coins/images/4713/large/polygon.png?1698233745',
      type: NetworkType.mainnet,
      rpcUrl: 'https://polygon-rpc.com',
      explorerUrl: 'https://polygonscan.com',
      transactionUrl: 'https://polygonscan.com/tx/',
    ),
    'polygon_amoy': NetworkConfig(
      name: 'Polygon Amoy',
      coin: 'matic',
      symbol: 'POL',
      chainId: 80002,
      network: 'polygon_amoy',
      decimals: 18,
      coingeckoId: 'matic-network',
      icon: 'https://coin-images.coingecko.com/coins/images/4713/large/polygon.png?1698233745',
      type: NetworkType.testnet,
      rpcUrl: 'https://rpc-amoy.polygon.technology',
      explorerUrl: 'https://amoy.polygonscan.com',
      transactionUrl: 'https://amoy.polygonscan.com/tx/',
    ),

    // Kaia
    'kaia': NetworkConfig(
      name: 'Kaia',
      coin: 'kaia',
      symbol: 'KAIA',
      chainId: 8217,
      network: 'kaia',
      decimals: 18,
      coingeckoId: 'kaia',
      icon: 'https://coin-images.coingecko.com/coins/images/39901/large/KAIA.png?1724734368',
      type: NetworkType.mainnet,
      rpcUrl: 'https://kaia-mainnet.nodit.io/',
      explorerUrl: 'https://kaiascan.io/',
      transactionUrl: 'https://kaiascan.io/tx/',
    ),
    'kaia_kairos': NetworkConfig(
      name: 'Kaia Kairos',
      coin: 'kaia',
      symbol: 'KAIA',
      chainId: 1001,
      network: 'kaia_kairos',
      decimals: 18,
      coingeckoId: 'kaia',
      icon: 'https://coin-images.coingecko.com/coins/images/39901/large/KAIA.png?1724734368',
      type: NetworkType.testnet,
      rpcUrl: 'https://rpc.ankr.com/klaytn_testnet',
      explorerUrl: 'https://kairos.kaiascan.io/',
      transactionUrl: 'https://kairos.kaiascan.io/tx/',
    ),

    // Arbitrum
    'arbitrum': NetworkConfig(
      name: 'Arbitrum One',
      coin: 'eth',
      symbol: 'ETH',
      chainId: 42161,
      network: 'arbitrum',
      decimals: 18,
      coingeckoId: 'arbitrum',
      icon: 'https://coin-images.coingecko.com/coins/images/16547/large/arb.jpg',
      type: NetworkType.mainnet,
      rpcUrl: 'https://arb1.arbitrum.io/rpc',
      explorerUrl: 'https://arbiscan.io',
      transactionUrl: 'https://arbiscan.io/tx/',
    ),
    'arbitrum_sepolia': NetworkConfig(
      name: 'Arbitrum Sepolia',
      coin: 'eth',
      symbol: 'ETH',
      chainId: 421614,
      network: 'arbitrum_sepolia',
      decimals: 18,
      coingeckoId: 'arbitrum',
      icon: 'https://coin-images.coingecko.com/coins/images/16547/large/arb.jpg',
      type: NetworkType.testnet,
      rpcUrl: 'https://sepolia-rollup.arbitrum.io/rpc',
      explorerUrl: 'https://sepolia.arbiscan.io',
      transactionUrl: 'https://sepolia.arbiscan.io/tx/',
    ),

    // Avalanche
    'avalanche': NetworkConfig(
      name: 'Avalanche C-Chain',
      coin: 'avax',
      symbol: 'AVAX',
      chainId: 43114,
      network: 'avalanche',
      decimals: 18,
      coingeckoId: 'avalanche-2',
      icon: 'https://coin-images.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png?1696512369',
      type: NetworkType.mainnet,
      rpcUrl: 'https://api.avax.network/ext/bc/C/rpc',
      explorerUrl: 'https://snowtrace.io',
      transactionUrl: 'https://snowtrace.io/tx/',
    ),
    'avalanche_fuji': NetworkConfig(
      name: 'Avalanche Fuji',
      coin: 'avax',
      symbol: 'AVAX',
      chainId: 43113,
      network: 'avalanche_fuji',
      decimals: 18,
      coingeckoId: 'avalanche-2',
      icon: 'https://coin-images.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png?1696512369',
      type: NetworkType.testnet,
      rpcUrl: 'https://api.avax-test.network/ext/bc/C/rpc',
      explorerUrl: 'https://testnet.snowtrace.io',
      transactionUrl: 'https://testnet.snowtrace.io/tx/',
    ),
  };

  // Network group constants
  static const List<String> solanaNetworks = ['solana', 'solana_devnet'];
  static const List<String> bitcoinNetworks = ['bitcoin', 'bitcoin_testnet'];
  static const List<String> kaiaNetworks = ['kaia', 'kaia_kairos'];
  static const List<String> evmNetworks = [
    'ethereum',
    'ethereum_sepolia',
    'binance',
    'binance_testnet',
    'polygon',
    'polygon_amoy',
    'arbitrum',
    'arbitrum_sepolia',
    'avalanche',
    'avalanche_fuji',
  ];

  // Helper functions

  /// Get network config by network name
  static NetworkConfig? getConfig(String network) {
    return configs[network.toLowerCase()];
  }

  /// Get network symbol
  static String getSymbol(String network) {
    return configs[network.toLowerCase()]?.symbol ?? network.toUpperCase();
  }

  /// Get network icon URL
  static String? getIcon(String network) {
    return configs[network.toLowerCase()]?.icon;
  }

  /// Check if network is Solana
  static bool isSolanaNetwork(String network) {
    return solanaNetworks.contains(network.toLowerCase());
  }

  /// Check if network is Bitcoin
  static bool isBitcoinNetwork(String network) {
    return bitcoinNetworks.contains(network.toLowerCase());
  }

  /// Check if network is Kaia
  static bool isKaiaNetwork(String network) {
    return kaiaNetworks.contains(network.toLowerCase());
  }

  /// Check if network is EVM compatible
  static bool isEvmNetwork(String network) {
    final lowerNetwork = network.toLowerCase();
    return evmNetworks.contains(lowerNetwork) ||
        kaiaNetworks.contains(lowerNetwork);
  }

  /// Get transaction explorer URL
  static String? getTransactionUrl(String network, String hash) {
    final config = configs[network.toLowerCase()];
    if (config == null) return null;
    return '${config.transactionUrl}$hash';
  }

  /// Get Bitcoin network based on environment
  static String getBitcoinNetwork(bool isDev) {
    return isDev ? 'bitcoin_testnet' : 'bitcoin';
  }

  /// Get Solana network based on environment
  static String getSolanaNetwork(bool isDev) {
    return isDev ? 'solana_devnet' : 'solana';
  }

  /// Get all mainnet networks
  static List<NetworkConfig> get mainnetConfigs {
    return configs.values.where((c) => c.isMainnet).toList();
  }

  /// Get all testnet networks
  static List<NetworkConfig> get testnetConfigs {
    return configs.values.where((c) => c.isTestnet).toList();
  }

  /// Get network config by chain ID (for EVM networks)
  static NetworkConfig? getByChainId(int chainId) {
    try {
      return configs.values.firstWhere((c) => c.chainId == chainId);
    } catch (_) {
      return null;
    }
  }
}

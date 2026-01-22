import 'package:equatable/equatable.dart';

class Chain extends Equatable {
  final String name;
  final String coin;
  final String symbol;
  final int chainId;
  final String network;
  final int decimals;
  final String coingeckoId;
  final String icon;
  final String type;
  final String rpcUrl;
  final String explorerUrl;
  final String explorerDetailUrl;

  const Chain({
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
    required this.explorerDetailUrl,
  });

  factory Chain.fromJson(Map<String, dynamic> json) {
    return Chain(
      name: json['name'] as String,
      coin: json['coin'] as String,
      symbol: json['symbol'] as String,
      chainId: json['chainId'] as int,
      network: json['network'] as String,
      decimals: json['decimals'] as int,
      coingeckoId: json['coingecko_id'] as String,
      icon: json['icon'] as String,
      type: json['type'] as String,
      rpcUrl: json['rpc_url'] as String,
      explorerUrl: json['explorer_url'] as String,
      explorerDetailUrl: json['explorer_detail_url'] as String,
    );
  }

  bool get isMainnet => type == 'mainnet';
  bool get isTestnet => type == 'testnet';

  @override
  List<Object?> get props => [chainId, network];
}

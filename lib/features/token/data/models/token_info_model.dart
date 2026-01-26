import '../../domain/entities/token_info.dart';

class TokenInfoModel {
  final String name;
  final String symbol;
  final String? platform;
  final int decimals;
  final String? logo;
  final bool isNative;
  final double balance;
  final double hrBalance;
  final String network;
  final String? contractAddress;
  final bool possibleSpam;
  final String? description;
  final String? website;
  final double? totalSupply;
  final double? priceUsd;
  final double? priceKrw;
  final List<double>? chartData;
  final String? mintAddress;
  final String? associatedTokenAddress;

  double? get valueUsd => priceUsd != null ? hrBalance * priceUsd! : null;

  const TokenInfoModel({
    required this.name,
    required this.symbol,
    this.platform,
    required this.decimals,
    this.logo,
    required this.isNative,
    required this.balance,
    required this.hrBalance,
    required this.network,
    this.contractAddress,
    required this.possibleSpam,
    this.description,
    this.website,
    this.totalSupply,
    this.priceUsd,
    this.priceKrw,
    this.chartData,
    this.mintAddress,
    this.associatedTokenAddress,
  });

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) {
    final price = json['price'] as Map<String, dynamic>?;
    final coingecko = price?['coingecko'] as Map<String, dynamic>?;
    final marketChart = json['marketChart'] as Map<String, dynamic>?;

    return TokenInfoModel(
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      platform: json['platform'] as String?,
      decimals: json['decimals'] as int? ?? 18,
      logo: json['logo'] as String?,
      isNative: json['isNative'] as bool? ?? false,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      hrBalance: (json['hrBalance'] as num?)?.toDouble() ?? 0,
      network: json['network'] as String? ?? '',
      contractAddress: json['contractAddress'] as String?,
      possibleSpam: json['possibleSpam'] as bool? ?? false,
      description: json['description'] as String?,
      website: json['website'] as String?,
      totalSupply: (json['totalSupply'] as num?)?.toDouble(),
      priceUsd: (coingecko?['USD'] as num?)?.toDouble(),
      priceKrw: (coingecko?['KRW'] as num?)?.toDouble(),
      chartData: _extractChartData(marketChart),
      mintAddress: json['mintAddress'] as String?,
      associatedTokenAddress: json['associatedTokenAddress'] as String?,
    );
  }

  factory TokenInfoModel.fromCacheJson(Map<String, dynamic> json) {
    return TokenInfoModel(
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      platform: json['platform'] as String?,
      decimals: json['decimals'] as int,
      logo: json['logo'] as String?,
      isNative: json['is_native'] as bool,
      balance: (json['balance'] as num).toDouble(),
      hrBalance: (json['hr_balance'] as num).toDouble(),
      network: json['network'] as String,
      contractAddress: json['contract_address'] as String?,
      possibleSpam: json['possible_spam'] as bool,
      description: json['description'] as String?,
      website: json['website'] as String?,
      totalSupply: (json['total_supply'] as num?)?.toDouble(),
      priceUsd: (json['price_usd'] as num?)?.toDouble(),
      priceKrw: (json['price_krw'] as num?)?.toDouble(),
      chartData: (json['chart_data'] as List?)?.cast<double>(),
      mintAddress: json['mint_address'] as String?,
      associatedTokenAddress: json['associated_token_address'] as String?,
    );
  }

  TokenInfo toEntity() {
    return TokenInfo(
      name: name,
      symbol: symbol,
      platform: platform,
      decimals: decimals,
      logo: logo,
      isNative: isNative,
      balance: balance,
      hrBalance: hrBalance,
      network: network,
      contractAddress: contractAddress,
      possibleSpam: possibleSpam,
      description: description,
      website: website,
      totalSupply: totalSupply,
      priceUsd: priceUsd,
      priceKrw: priceKrw,
      chartData: chartData,
      mintAddress: mintAddress,
      associatedTokenAddress: associatedTokenAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'platform': platform,
      'decimals': decimals,
      'logo': logo,
      'is_native': isNative,
      'balance': balance,
      'hr_balance': hrBalance,
      'network': network,
      'contract_address': contractAddress,
      'possible_spam': possibleSpam,
      'description': description,
      'website': website,
      'total_supply': totalSupply,
      'price_usd': priceUsd,
      'price_krw': priceKrw,
      'chart_data': chartData,
      'mint_address': mintAddress,
      'associated_token_address': associatedTokenAddress,
    };
  }

  static List<double>? _extractChartData(Map<String, dynamic>? marketChart) {
    if (marketChart == null) return null;

    final coingecko = marketChart['coingecko'] as Map<String, dynamic>?;
    if (coingecko == null) return null;

    final usdData = coingecko['USD'] as List?;
    if (usdData == null || usdData.isEmpty) return null;

    try {
      return usdData.map((e) {
        if (e is List && e.length >= 2) {
          return (e[1] as num).toDouble();
        }
        return 0.0;
      }).toList();
    } catch (_) {
      return null;
    }
  }
}

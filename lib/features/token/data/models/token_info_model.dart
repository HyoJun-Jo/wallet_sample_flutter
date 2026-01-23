import '../../domain/entities/token_info.dart';

/// Token info model (matches SDK)
class TokenInfoModel extends TokenInfo {
  const TokenInfoModel({
    required super.name,
    required super.symbol,
    super.platform,
    required super.decimals,
    super.logo,
    required super.isNative,
    required super.balance,
    required super.hrBalance,
    required super.network,
    super.contractAddress,
    required super.possibleSpam,
    super.description,
    super.website,
    super.totalSupply,
    super.priceUsd,
    super.priceKrw,
    super.chartData,
    super.mintAddress,
    super.associatedTokenAddress,
  });

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) {
    // Parse nested price object
    final price = json['price'] as Map<String, dynamic>?;
    final coingecko = price?['coingecko'] as Map<String, dynamic>?;

    // Parse marketChart for chartData
    final marketChart = json['marketChart'] as Map<String, dynamic>?;
    final chartData = _extractChartData(marketChart);

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
      chartData: chartData,
      mintAddress: json['mintAddress'] as String?,
      associatedTokenAddress: json['associatedTokenAddress'] as String?,
    );
  }

  /// Extract chart data from marketChart object
  /// API format: { "coingecko": { "USD": [[timestamp, price], ...] } }
  static List<double>? _extractChartData(Map<String, dynamic>? marketChart) {
    if (marketChart == null) return null;

    final coingecko = marketChart['coingecko'] as Map<String, dynamic>?;
    if (coingecko == null) return null;

    final usdData = coingecko['USD'] as List?;
    if (usdData == null || usdData.isEmpty) return null;

    // Convert [[timestamp, price], ...] to [price, price, ...]
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'platform': platform,
      'decimals': decimals,
      'logo': logo,
      'isNative': isNative,
      'balance': balance,
      'hrBalance': hrBalance,
      'network': network,
      'contractAddress': contractAddress,
      'possibleSpam': possibleSpam,
      'description': description,
      'website': website,
      'totalSupply': totalSupply,
      'price': {
        'coingecko': {
          if (priceUsd != null) 'USD': priceUsd,
          if (priceKrw != null) 'KRW': priceKrw,
        },
      },
      if (chartData != null)
        'marketChart': {
          'coingecko': {
            'USD': chartData!.map((p) => [0, p]).toList(),
          },
        },
      'mintAddress': mintAddress,
      'associatedTokenAddress': associatedTokenAddress,
    };
  }
}

/// Token allowance model
class TokenAllowanceModel extends TokenAllowance {
  const TokenAllowanceModel({
    required super.contractAddress,
    required super.spender,
    required super.allowance,
  });

  factory TokenAllowanceModel.fromJson(Map<String, dynamic> json) {
    return TokenAllowanceModel(
      contractAddress: json['contract_address'] as String,
      spender: json['spender'] as String,
      allowance: json['allowance'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contract_address': contractAddress,
      'spender': spender,
      'allowance': allowance,
    };
  }
}

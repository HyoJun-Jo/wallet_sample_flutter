import '../../domain/entities/token_info.dart';

/// Token info model (based on Android ABCToken model)
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
    super.priceUsd,
    super.priceKrw,
    super.mintAddress,
    super.associatedTokenAddress,
  });

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) {
    // Parse nested price object
    final price = json['price'] as Map<String, dynamic>?;
    final coingecko = price?['coingecko'] as Map<String, dynamic>?;

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
      priceUsd: (coingecko?['USD'] as num?)?.toDouble(),
      priceKrw: (coingecko?['KRW'] as num?)?.toDouble(),
      mintAddress: json['mintAddress'] as String?,
      associatedTokenAddress: json['associatedTokenAddress'] as String?,
    );
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
      'price': {
        'coingecko': {
          if (priceUsd != null) 'USD': priceUsd,
          if (priceKrw != null) 'KRW': priceKrw,
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

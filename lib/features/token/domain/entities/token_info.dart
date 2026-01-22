import 'package:equatable/equatable.dart';

import '../../../../core/utils/format_utils.dart';

/// Token information entity (based on Android ABCToken model)
class TokenInfo extends Equatable {
  final String name;
  final String symbol;
  final String? platform;
  final int decimals;
  final String? logo;
  final bool isNative;
  final double balance;
  final double hrBalance; // human readable balance
  final String network;
  final String? contractAddress;
  final bool possibleSpam;
  final double? priceUsd;
  final double? priceKrw;
  final String? mintAddress; // Solana
  final String? associatedTokenAddress; // Solana

  const TokenInfo({
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
    this.priceUsd,
    this.priceKrw,
    this.mintAddress,
    this.associatedTokenAddress,
  });

  /// USD value calculation
  double? get valueUsd => priceUsd != null ? hrBalance * priceUsd! : null;

  /// KRW value calculation
  double? get valueKrw => priceKrw != null ? hrBalance * priceKrw! : null;

  /// Returns formatted balance (e.g., "1.234")
  String get formattedBalance => FormatUtils.formatBalance(hrBalance);

  /// Returns formatted USD value (e.g., "$1,234.56")
  String get formattedValueUsd => FormatUtils.formatUsd(valueUsd);

  @override
  List<Object?> get props => [
        name,
        symbol,
        platform,
        decimals,
        logo,
        isNative,
        balance,
        hrBalance,
        network,
        contractAddress,
        possibleSpam,
        priceUsd,
        priceKrw,
        mintAddress,
        associatedTokenAddress,
      ];
}

/// Token allowance information
class TokenAllowance extends Equatable {
  final String contractAddress;
  final String spender;
  final String allowance;

  const TokenAllowance({
    required this.contractAddress,
    required this.spender,
    required this.allowance,
  });

  @override
  List<Object?> get props => [contractAddress, spender, allowance];
}

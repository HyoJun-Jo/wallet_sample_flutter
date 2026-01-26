import 'package:equatable/equatable.dart';

import '../../../../core/utils/format_utils.dart';

/// Token information entity (based on SDK tokenEntities.ts)
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
  final String? description;
  final String? website;
  final double? totalSupply;
  final double? priceUsd;
  final double? priceKrw;
  final List<double>? chartData; // 30-day price chart data
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
    this.description,
    this.website,
    this.totalSupply,
    this.priceUsd,
    this.priceKrw,
    this.chartData,
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

  /// Market cap (totalSupply * priceUsd)
  double? get marketCap {
    if (totalSupply == null || priceUsd == null) return null;
    return totalSupply! * priceUsd!;
  }

  /// Price change percent (latest vs before latest from chartData)
  double? get priceChangePercent {
    if (chartData == null || chartData!.length < 2) return null;
    final latestValue = chartData![chartData!.length - 1];
    final beforeLatestValue = chartData![chartData!.length - 2];
    if (latestValue <= 0) return null;
    final gap = latestValue - beforeLatestValue;
    return (gap / latestValue) * 100;
  }

  /// 1-day price change percent
  double? get priceChange1d {
    if (chartData == null || chartData!.length < 2) return null;
    final today = chartData![chartData!.length - 1];
    final yesterday = chartData![chartData!.length - 2];
    if (today <= 0) return null;
    return ((today - yesterday) / today) * 100;
  }

  /// 1-week price change percent
  double? get priceChange1w {
    if (chartData == null || chartData!.length < 7) return null;
    final today = chartData![chartData!.length - 1];
    final lastWeek = chartData![chartData!.length - 7];
    if (today <= 0) return null;
    return ((today - lastWeek) / today) * 100;
  }

  /// 1-month price change percent
  double? get priceChange1m {
    if (chartData == null || chartData!.length < 30) return null;
    final today = chartData![chartData!.length - 1];
    final lastMonth = chartData![0];
    if (today <= 0) return null;
    return ((today - lastMonth) / today) * 100;
  }

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
        description,
        website,
        totalSupply,
        priceUsd,
        priceKrw,
        chartData,
        mintAddress,
        associatedTokenAddress,
      ];
}

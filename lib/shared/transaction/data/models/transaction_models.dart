import '../../../../core/utils/wei_utils.dart';
import '../../domain/entities/transaction_entities.dart';

/// Gas fees DTO from API
class GasFeesModel {
  final GasFeeDetailModel low;
  final GasFeeDetailModel medium;
  final GasFeeDetailModel high;
  final String estimatedBaseFee;
  final double? networkCongestion;
  final List<String>? latestPriorityFeeRange;
  final List<String>? historicalPriorityFeeRange;
  final List<String>? historicalBaseFeeRange;
  final String? priorityFeeTrend;
  final String? baseFeeTrend;

  const GasFeesModel({
    required this.low,
    required this.medium,
    required this.high,
    required this.estimatedBaseFee,
    this.networkCongestion,
    this.latestPriorityFeeRange,
    this.historicalPriorityFeeRange,
    this.historicalBaseFeeRange,
    this.priorityFeeTrend,
    this.baseFeeTrend,
  });

  factory GasFeesModel.fromJson(Map<String, dynamic> json) {
    return GasFeesModel(
      low: GasFeeDetailModel.fromJson(json['low'] as Map<String, dynamic>? ?? {}),
      medium: GasFeeDetailModel.fromJson(json['medium'] as Map<String, dynamic>? ?? {}),
      high: GasFeeDetailModel.fromJson(json['high'] as Map<String, dynamic>? ?? {}),
      estimatedBaseFee: json['estimatedBaseFee']?.toString() ?? '0',
      networkCongestion: (json['networkCongestion'] as num?)?.toDouble(),
      latestPriorityFeeRange: (json['latestPriorityFeeRange'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      historicalPriorityFeeRange: (json['historicalPriorityFeeRange'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      historicalBaseFeeRange: (json['historicalBaseFeeRange'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      priorityFeeTrend: json['priorityFeeTrend']?.toString(),
      baseFeeTrend: json['baseFeeTrend']?.toString(),
    );
  }

  GasFees toEntity(String network) {
    return GasFees(
      low: low.toEntity(),
      medium: medium.toEntity(),
      high: high.toEntity(),
      baseFee: estimatedBaseFee,
      network: network,
    );
  }
}

/// Gas fee detail DTO
class GasFeeDetailModel {
  final String suggestedMaxFeePerGas;
  final String suggestedMaxPriorityFeePerGas;
  final int minWaitTimeEstimate;
  final int maxWaitTimeEstimate;

  const GasFeeDetailModel({
    required this.suggestedMaxFeePerGas,
    required this.suggestedMaxPriorityFeePerGas,
    required this.minWaitTimeEstimate,
    required this.maxWaitTimeEstimate,
  });

  factory GasFeeDetailModel.fromJson(Map<String, dynamic> json) {
    return GasFeeDetailModel(
      suggestedMaxFeePerGas: json['suggestedMaxFeePerGas']?.toString() ?? '0',
      suggestedMaxPriorityFeePerGas: json['suggestedMaxPriorityFeePerGas']?.toString() ?? '0',
      minWaitTimeEstimate: json['minWaitTimeEstimate'] as int? ?? 0,
      maxWaitTimeEstimate: json['maxWaitTimeEstimate'] as int? ?? 0,
    );
  }

  GasFeeDetail toEntity() {
    // Convert gwei to wei hex, calculate average wait time
    final avgWaitTimeSeconds = ((minWaitTimeEstimate + maxWaitTimeEstimate) / 2 / 1000).round();
    return GasFeeDetail(
      maxFeePerGas: WeiUtils.gweiToWeiHex(suggestedMaxFeePerGas),
      maxPriorityFeePerGas: WeiUtils.gweiToWeiHex(suggestedMaxPriorityFeePerGas),
      estimatedTime: avgWaitTimeSeconds,
    );
  }
}

/// Transaction result DTO
class TransactionResultModel {
  final String result;

  const TransactionResultModel({required this.result});

  factory TransactionResultModel.fromJson(Map<String, dynamic> json) {
    return TransactionResultModel(
      result: json['result']?.toString() ??
          json['hash']?.toString() ??
          json['txHash']?.toString() ??
          '',
    );
  }

  TransactionResult toEntity() {
    return TransactionResult(transactionHash: result);
  }
}

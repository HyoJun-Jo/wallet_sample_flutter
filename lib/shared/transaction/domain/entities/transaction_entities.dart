import 'package:equatable/equatable.dart';

/// Gas fee info
class GasFees extends Equatable {
  final GasFeeDetail low;
  final GasFeeDetail medium;
  final GasFeeDetail high;
  final String baseFee;
  final String network;

  const GasFees({
    required this.low,
    required this.medium,
    required this.high,
    required this.baseFee,
    required this.network,
  });

  @override
  List<Object?> get props => [low, medium, high, baseFee, network];
}

/// Gas fee detail (EIP-1559)
class GasFeeDetail extends Equatable {
  final String maxFeePerGas;
  final String maxPriorityFeePerGas;
  final int? estimatedTime;

  const GasFeeDetail({
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    this.estimatedTime,
  });

  @override
  List<Object?> get props => [maxFeePerGas, maxPriorityFeePerGas, estimatedTime];
}

/// Estimate gas params
class EstimateGasParams extends Equatable {
  final String network;
  final String from;
  final String to;
  final String? value;
  final String? data;

  const EstimateGasParams({
    required this.network,
    required this.from,
    required this.to,
    this.value,
    this.data,
  });

  @override
  List<Object?> get props => [network, from, to, value, data];
}

/// Estimate gas result
class EstimateGasResult extends Equatable {
  final String gasLimit;

  const EstimateGasResult({required this.gasLimit});

  @override
  List<Object?> get props => [gasLimit];
}

/// Send transaction params
class SendTransactionParams extends Equatable {
  final String network;
  final String signedTx;

  const SendTransactionParams({
    required this.network,
    required this.signedTx,
  });

  @override
  List<Object?> get props => [network, signedTx];
}

/// Transaction result
class TransactionResult extends Equatable {
  final String txHash;

  const TransactionResult({required this.txHash});

  @override
  List<Object?> get props => [txHash];
}

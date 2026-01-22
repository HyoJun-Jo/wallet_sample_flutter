import 'package:equatable/equatable.dart';

/// Transfer request entity
class TransferRequest extends Equatable {
  final String fromAddress;
  final String toAddress;
  final String amount;
  final String contractAddress;
  final String network;

  const TransferRequest({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.contractAddress,
    required this.network,
  });

  @override
  List<Object?> get props => [
        fromAddress,
        toAddress,
        amount,
        contractAddress,
        network,
      ];
}

/// Transfer data (transaction data required for signing)
/// Uses EIP-1559 format with maxFeePerGas and maxPriorityFeePerGas
class TransferData extends Equatable {
  final String to;
  final String from;
  final String data;
  final String value;
  final String gasLimit;
  final String maxFeePerGas;
  final String maxPriorityFeePerGas;
  final String nonce;
  final String network;

  const TransferData({
    required this.to,
    required this.from,
    required this.data,
    required this.value,
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.nonce,
    required this.network,
  });

  @override
  List<Object?> get props => [
        to,
        from,
        data,
        value,
        gasLimit,
        maxFeePerGas,
        maxPriorityFeePerGas,
        nonce,
        network,
      ];
}

/// Transfer result
class TransferResult extends Equatable {
  final String txHash;
  final TransferStatus status;

  const TransferResult({
    required this.txHash,
    required this.status,
  });

  @override
  List<Object?> get props => [txHash, status];
}

/// Transfer status
enum TransferStatus {
  pending,
  submitted,
  confirmed,
  failed,
}

import 'package:equatable/equatable.dart';

import '../../../../shared/transaction/domain/entities/transaction_entities.dart';

// ============================================================================
// Transfer Entities (matches SDK tokenEntities.ts)
// ============================================================================

/// Parameters for getting transfer data (ERC-20 ABI data)
class GetTransferDataParams extends Equatable {
  final String network;
  final String to;
  final String? from;
  final String value;

  const GetTransferDataParams({
    required this.network,
    required this.to,
    this.from,
    required this.value,
  });

  @override
  List<Object?> get props => [network, to, from, value];
}

/// Result of getTransferData (ERC-20 transfer() ABI data)
class TransferDataResult extends Equatable {
  final String data;

  const TransferDataResult({required this.data});

  @override
  List<Object?> get props => [data];
}

/// Parameters for token transfer (matches SDK TransferParams)
class TransferParams extends Equatable {
  final String fromAddress;
  final String toAddress;
  final String? contractAddress;
  final String amount;
  final int decimals;
  final String network;
  final GasFeeDetail gasFee;
  final String gasLimit;

  const TransferParams({
    required this.fromAddress,
    required this.toAddress,
    this.contractAddress,
    required this.amount,
    required this.decimals,
    required this.network,
    required this.gasFee,
    required this.gasLimit,
  });

  /// Check if this is a native token transfer
  bool get isNative => contractAddress == null || contractAddress!.isEmpty;

  @override
  List<Object?> get props => [
        fromAddress,
        toAddress,
        contractAddress,
        amount,
        decimals,
        network,
        gasFee,
        gasLimit,
      ];
}

/// Transfer result (matches SDK TransferResult)
class TransferResult extends Equatable {
  final String transactionHash;

  const TransferResult({required this.transactionHash});

  @override
  List<Object?> get props => [transactionHash];
}

// ============================================================================
// Legacy entities (for backward compatibility during migration)
// ============================================================================

/// Transfer request entity (legacy - use TransferParams instead)
@Deprecated('Use TransferParams instead')
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

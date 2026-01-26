import 'package:equatable/equatable.dart';

import '../../../../shared/transaction/domain/entities/transaction_entities.dart';

// ============================================================================
// Token Transfer Entities (matches SDK tokenEntities.ts)
// ============================================================================

/// Parameters for getting transfer data (ERC-20 ABI data)
class GetTokenTransferDataParams extends Equatable {
  final String network;
  final String to;
  final String? from;
  final String value;

  const GetTokenTransferDataParams({
    required this.network,
    required this.to,
    this.from,
    required this.value,
  });

  @override
  List<Object?> get props => [network, to, from, value];
}

/// Result of getTransferData (ERC-20 transfer() ABI data)
class TokenTransferDataResult extends Equatable {
  final String data;

  const TokenTransferDataResult({required this.data});

  @override
  List<Object?> get props => [data];
}

/// Parameters for token transfer (matches SDK TransferParams)
class TokenTransferParams extends Equatable {
  final String fromAddress;
  final String toAddress;
  final String? contractAddress;
  final String amount;
  final int decimals;
  final String network;
  final GasFeeDetail gasFee;
  final String gasLimit;

  const TokenTransferParams({
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
class TokenTransferResult extends Equatable {
  final String transactionHash;

  const TokenTransferResult({required this.transactionHash});

  @override
  List<Object?> get props => [transactionHash];
}

/// Transfer data (transaction data required for signing)
/// Uses EIP-1559 format with maxFeePerGas and maxPriorityFeePerGas
class TokenTransferData extends Equatable {
  final String to;
  final String from;
  final String data;
  final String value;
  final String gasLimit;
  final String maxFeePerGas;
  final String maxPriorityFeePerGas;
  final String nonce;
  final String network;

  const TokenTransferData({
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

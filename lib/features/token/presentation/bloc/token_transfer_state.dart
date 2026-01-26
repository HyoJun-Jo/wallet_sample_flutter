import 'package:equatable/equatable.dart';

import '../../domain/entities/token_transfer.dart';

/// Token transfer state base class
abstract class TokenTransferState extends Equatable {
  const TokenTransferState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TokenTransferInitial extends TokenTransferState {
  const TokenTransferInitial();
}

/// Loading state (preparing or transferring)
class TokenTransferLoading extends TokenTransferState {
  const TokenTransferLoading();
}

/// Transfer data ready (for confirmation UI)
class TokenTransferDataReady extends TokenTransferState {
  final TokenTransferData transferData;
  final TokenTransferParams transferParams;

  const TokenTransferDataReady({
    required this.transferData,
    required this.transferParams,
  });

  @override
  List<Object?> get props => [transferData, transferParams];
}

/// Transfer completed successfully
class TokenTransferCompleted extends TokenTransferState {
  final TokenTransferResult result;

  const TokenTransferCompleted({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Error state
class TokenTransferError extends TokenTransferState {
  final String message;

  const TokenTransferError({required this.message});

  @override
  List<Object?> get props => [message];
}

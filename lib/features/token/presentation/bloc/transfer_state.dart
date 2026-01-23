import 'package:equatable/equatable.dart';

import '../../domain/entities/transfer.dart';

/// Transfer state base class
abstract class TransferState extends Equatable {
  const TransferState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TransferInitial extends TransferState {
  const TransferInitial();
}

/// Loading state (preparing or transferring)
class TransferLoading extends TransferState {
  const TransferLoading();
}

/// Transfer data ready (for confirmation UI)
class TransferDataReady extends TransferState {
  final TransferData transferData;
  final TransferParams transferParams;

  const TransferDataReady({
    required this.transferData,
    required this.transferParams,
  });

  @override
  List<Object?> get props => [transferData, transferParams];
}

/// Transfer completed successfully
class TransferCompleted extends TransferState {
  final TransferResult result;

  const TransferCompleted({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Error state
class TransferError extends TransferState {
  final String message;

  const TransferError({required this.message});

  @override
  List<Object?> get props => [message];
}

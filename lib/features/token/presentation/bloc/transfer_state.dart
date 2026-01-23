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

/// Loading state
class TransferLoading extends TransferState {
  const TransferLoading();
}

/// Transfer data ready (waiting for signature)
class TransferDataReady extends TransferState {
  final TransferData transferData;

  const TransferDataReady({required this.transferData});

  @override
  List<Object?> get props => [transferData];
}

/// Transfer completed
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

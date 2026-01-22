import 'package:equatable/equatable.dart';
import '../../domain/entities/sign_request.dart';

/// Signing state base class
abstract class SigningState extends Equatable {
  const SigningState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SigningInitial extends SigningState {
  const SigningInitial();
}

/// Loading state
class SigningLoading extends SigningState {
  const SigningLoading();
}

/// Signing completed
class SigningCompleted extends SigningState {
  final SignResult result;

  const SigningCompleted({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Error state
class SigningError extends SigningState {
  final String message;

  const SigningError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Transaction sent successfully
class TransactionSent extends SigningState {
  final String txHash;

  const TransactionSent({required this.txHash});

  @override
  List<Object?> get props => [txHash];
}

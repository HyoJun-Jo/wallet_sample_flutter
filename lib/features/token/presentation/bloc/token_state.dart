import 'package:equatable/equatable.dart';
import '../../domain/entities/token_info.dart';

/// Token state base class
abstract class TokenState extends Equatable {
  const TokenState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TokenInitial extends TokenState {
  const TokenInitial();
}

/// Loading state
class TokenLoading extends TokenState {
  const TokenLoading();
}

/// All tokens loaded successfully
class AllTokensLoaded extends TokenState {
  final List<TokenInfo> tokens;
  final double totalValueUsd;
  final double totalValueKrw;
  final String walletAddress;

  const AllTokensLoaded({
    required this.tokens,
    required this.totalValueUsd,
    required this.totalValueKrw,
    required this.walletAddress,
  });

  @override
  List<Object?> get props => [tokens, totalValueUsd, totalValueKrw, walletAddress];
}

/// Error state
class TokenError extends TokenState {
  final String message;

  const TokenError({required this.message});

  @override
  List<Object?> get props => [message];
}

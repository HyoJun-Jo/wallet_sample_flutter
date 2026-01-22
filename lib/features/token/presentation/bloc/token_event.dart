import 'package:equatable/equatable.dart';
import '../../domain/entities/token_info.dart';

/// Token event base class
abstract class TokenEvent extends Equatable {
  const TokenEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load all tokens for a wallet (cache-first)
class AllTokensRequested extends TokenEvent {
  final String walletAddress;
  /// Comma-separated network names (e.g., "ethereum,polygon,binance")
  final String networks;
  /// If true, returns minimal token info (faster response)
  final bool minimalInfo;

  const AllTokensRequested({
    required this.walletAddress,
    required this.networks,
    this.minimalInfo = false,
  });

  @override
  List<Object?> get props => [walletAddress, networks, minimalInfo];
}

/// Tokens refreshed from background API call
class TokensRefreshed extends TokenEvent {
  final List<TokenInfo> tokens;

  const TokensRefreshed({required this.tokens});

  @override
  List<Object?> get props => [tokens];
}

/// Request to refresh tokens (force API call)
class TokenRefreshRequested extends TokenEvent {
  const TokenRefreshRequested();
}

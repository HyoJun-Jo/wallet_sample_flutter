import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/usecases/get_all_tokens_usecase.dart';
import 'token_event.dart';
import 'token_state.dart';

/// Token BLoC
class TokenBloc extends Bloc<TokenEvent, TokenState> {
  final GetAllTokensUseCase _getAllTokensUseCase;

  String? _lastWalletAddress;
  String? _lastNetworks;
  bool _lastMinimalInfo = false;

  TokenBloc({
    required GetAllTokensUseCase getAllTokensUseCase,
  })  : _getAllTokensUseCase = getAllTokensUseCase,
        super(const TokenInitial()) {
    on<AllTokensRequested>(_onAllTokensRequested);
    on<TokensRefreshed>(_onTokensRefreshed);
    on<TokenRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onAllTokensRequested(
    AllTokensRequested event,
    Emitter<TokenState> emit,
  ) async {
    emit(const TokenLoading());

    _lastWalletAddress = event.walletAddress;
    _lastNetworks = event.networks;
    _lastMinimalInfo = event.minimalInfo;

    final result = await _getAllTokensUseCase(GetAllTokensParams(
      walletAddress: event.walletAddress,
      networks: event.networks,
      minimalInfo: event.minimalInfo,
      onRefresh: (tokens) {
        // Trigger refresh event when background API call completes
        add(TokensRefreshed(tokens: tokens));
      },
    ));

    result.fold(
      (failure) => emit(TokenError(message: failure.message)),
      (tokens) {
        final totalUsd = _calculateTotalValueUsd(tokens);
        final totalKrw = _calculateTotalValueKrw(tokens);
        emit(AllTokensLoaded(
          tokens: tokens,
          totalValueUsd: totalUsd,
          totalValueKrw: totalKrw,
          walletAddress: event.walletAddress,
          isFromCache: true, // First response may be from cache
        ));
      },
    );
  }

  void _onTokensRefreshed(
    TokensRefreshed event,
    Emitter<TokenState> emit,
  ) {
    final currentState = state;
    if (currentState is AllTokensLoaded) {
      final totalUsd = _calculateTotalValueUsd(event.tokens);
      final totalKrw = _calculateTotalValueKrw(event.tokens);
      emit(AllTokensLoaded(
        tokens: event.tokens,
        totalValueUsd: totalUsd,
        totalValueKrw: totalKrw,
        walletAddress: currentState.walletAddress,
        isFromCache: false, // This is fresh from API
      ));
    }
  }

  Future<void> _onRefreshRequested(
    TokenRefreshRequested event,
    Emitter<TokenState> emit,
  ) async {
    if (_lastWalletAddress != null && _lastNetworks != null) {
      add(AllTokensRequested(
        walletAddress: _lastWalletAddress!,
        networks: _lastNetworks!,
        minimalInfo: _lastMinimalInfo,
      ));
    }
  }

  double _calculateTotalValueUsd(List<TokenInfo> tokens) {
    return tokens.fold<double>(0, (sum, t) => sum + (t.valueUsd ?? 0));
  }

  double _calculateTotalValueKrw(List<TokenInfo> tokens) {
    return tokens.fold<double>(0, (sum, t) => sum + (t.valueKrw ?? 0));
  }
}

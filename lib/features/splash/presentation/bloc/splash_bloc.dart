import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;
  final WalletRepository _walletRepository;

  SplashBloc({
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
    required WalletRepository walletRepository,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage,
        _walletRepository = walletRepository,
        super(const SplashInitial()) {
    on<SplashCheckRequested>(_onCheckRequested);
  }

  Future<void> _onCheckRequested(
    SplashCheckRequested event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashChecking());

    try {
      // Wait for splash animation (minimum 2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // Check if access token exists
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        // No token - navigate to login
        emit(const SplashNavigateToLogin());
        return;
      }

      // Check if auto login is enabled
      final autoLogin = _localStorage.getBool(LocalStorageKeys.autoLogin) ?? false;

      if (!autoLogin) {
        // Auto login disabled - navigate to login
        emit(const SplashNavigateToLogin());
        return;
      }

      // Check if wallet exists
      final walletsResult = await _walletRepository.getSavedWallets();

      walletsResult.fold(
        (failure) {
          // Failed to get wallets - navigate to login
          emit(const SplashNavigateToLogin());
        },
        (wallets) {
          if (wallets.isEmpty) {
            // No wallet - navigate to wallet creation
            emit(const SplashNavigateToWalletCreate());
          } else {
            // Has wallet - navigate to main
            emit(SplashNavigateToMain(walletAddress: wallets.first.address));
          }
        },
      );
    } catch (e) {
      emit(SplashError(message: e.toString()));
    }
  }
}

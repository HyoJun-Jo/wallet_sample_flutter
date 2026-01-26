import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/wallet/domain/repositories/wallet_repository.dart';
import '../../../../shared/wallet/domain/usecases/create_wallet_usecase.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

/// Wallet BLoC
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final CreateWalletUseCase _createWalletUseCase;
  final WalletRepository _walletRepository;

  WalletBloc({
    required CreateWalletUseCase createWalletUseCase,
    required WalletRepository walletRepository,
  })  : _createWalletUseCase = createWalletUseCase,
        _walletRepository = walletRepository,
        super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletCreateRequested>(_onCreateRequested);
    on<WalletDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _walletRepository.getWalletCredentials();

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (credentials) => emit(WalletLoaded(credentials: credentials)),
    );
  }

  Future<void> _onCreateRequested(
    WalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _createWalletUseCase(CreateWalletParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (credentials) => emit(WalletCreated(credentials: credentials)),
    );
  }

  Future<void> _onDeleteRequested(
    WalletDeleteRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _walletRepository.deleteWallet();

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (_) => emit(const WalletDeleted()),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/wallet/repositories/wallet_repository.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
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
    on<WalletListRequested>(_onListRequested);
    on<WalletCreateRequested>(_onCreateRequested);
    on<WalletDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onListRequested(
    WalletListRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _walletRepository.getSavedWallets();

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (wallets) => emit(WalletListLoaded(wallets: wallets)),
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
      (createResult) => emit(WalletCreated(result: createResult)),
    );
  }

  Future<void> _onDeleteRequested(
    WalletDeleteRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await _walletRepository.deleteWallet(address: event.address);

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (_) => emit(const WalletDeleted()),
    );
  }
}

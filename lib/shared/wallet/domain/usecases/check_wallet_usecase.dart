import '../../../../core/usecases/usecase.dart';
import '../repositories/wallet_repository.dart';

/// Check if wallet exists locally
class CheckWalletUseCase implements UseCaseNoFailure<bool, NoParams> {
  final WalletRepository _repository;

  CheckWalletUseCase(this._repository);

  @override
  Future<bool> call(NoParams params) {
    return _repository.checkWallet();
  }
}

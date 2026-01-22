import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

/// Create wallet UseCase
class CreateWalletUseCase implements UseCase<WalletCreateResult, CreateWalletParams> {
  final WalletRepository _repository;

  CreateWalletUseCase(this._repository);

  @override
  Future<Either<Failure, WalletCreateResult>> call(CreateWalletParams params) {
    return _repository.createWallet(
      email: params.email,
      password: params.password,
    );
  }
}

class CreateWalletParams extends Equatable {
  final String email;
  final String password;

  const CreateWalletParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

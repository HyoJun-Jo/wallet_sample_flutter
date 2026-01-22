import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/signing_repository.dart';

/// Send Signed Transaction UseCase
class SendSignedTransactionUseCase implements UseCase<String, SendSignedTransactionParams> {
  final SigningRepository _repository;

  SendSignedTransactionUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(SendSignedTransactionParams params) {
    return _repository.sendTransaction(
      network: params.network,
      signedTx: params.signedTx,
    );
  }
}

class SendSignedTransactionParams extends Equatable {
  final String network;
  final String signedTx;

  const SendSignedTransactionParams({
    required this.network,
    required this.signedTx,
  });

  @override
  List<Object?> get props => [network, signedTx];
}

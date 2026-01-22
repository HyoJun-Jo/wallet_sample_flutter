import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/signing_repository.dart';

/// Get Nonce UseCase
class GetNonceUseCase implements UseCase<String, GetNonceParams> {
  final SigningRepository _repository;

  GetNonceUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(GetNonceParams params) {
    return _repository.getNonce(
      address: params.address,
      network: params.network,
    );
  }
}

class GetNonceParams extends Equatable {
  final String address;
  final String network;

  const GetNonceParams({
    required this.address,
    required this.network,
  });

  @override
  List<Object?> get props => [address, network];
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sign_request.dart';
import '../repositories/signing_repository.dart';

/// Get Suggested Gas Fees UseCase
class GetSuggestedGasFeesUseCase implements UseCase<GasFeeInfo, GetSuggestedGasFeesParams> {
  final SigningRepository _repository;

  GetSuggestedGasFeesUseCase(this._repository);

  @override
  Future<Either<Failure, GasFeeInfo>> call(GetSuggestedGasFeesParams params) {
    return _repository.getSuggestedGasFees(network: params.network);
  }
}

class GetSuggestedGasFeesParams extends Equatable {
  final String network;

  const GetSuggestedGasFeesParams({required this.network});

  @override
  List<Object?> get props => [network];
}

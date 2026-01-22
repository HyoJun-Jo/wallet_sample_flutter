import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/signing_repository.dart';

/// Estimate Gas UseCase
class EstimateGasUseCase implements UseCase<String, EstimateGasParams> {
  final SigningRepository _repository;

  EstimateGasUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(EstimateGasParams params) {
    return _repository.estimateGas(
      network: params.network,
      from: params.from,
      to: params.to,
      value: params.value,
      data: params.data,
    );
  }
}

class EstimateGasParams extends Equatable {
  final String network;
  final String from;
  final String to;
  final String value;
  final String data;

  const EstimateGasParams({
    required this.network,
    required this.from,
    required this.to,
    required this.value,
    required this.data,
  });

  @override
  List<Object?> get props => [network, from, to, value, data];
}

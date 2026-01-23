import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transfer.dart';
import '../repositories/transfer_repository.dart';

/// Create transfer data UseCase
class CreateTransferDataUseCase implements UseCase<TransferData, CreateTransferDataParams> {
  final TransferRepository _repository;

  CreateTransferDataUseCase(this._repository);

  @override
  Future<Either<Failure, TransferData>> call(CreateTransferDataParams params) {
    return _repository.createTransferData(request: params.request);
  }
}

class CreateTransferDataParams extends Equatable {
  final TransferRequest request;

  const CreateTransferDataParams({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Send transaction UseCase
class SendTransactionUseCase implements UseCase<TransferResult, SendTransactionParams> {
  final TransferRepository _repository;

  SendTransactionUseCase(this._repository);

  @override
  Future<Either<Failure, TransferResult>> call(SendTransactionParams params) {
    return _repository.sendTransaction(
      network: params.network,
      rawData: params.rawData,
    );
  }
}

class SendTransactionParams extends Equatable {
  final String network;
  final String rawData;

  const SendTransactionParams({
    required this.network,
    required this.rawData,
  });

  @override
  List<Object?> get props => [network, rawData];
}

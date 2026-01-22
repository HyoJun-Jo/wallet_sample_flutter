import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transfer.dart';

/// Transfer Repository interface
abstract class TransferRepository {
  /// Create transfer data
  Future<Either<Failure, TransferData>> createTransferData({
    required TransferRequest request,
  });

  /// Send raw transaction
  Future<Either<Failure, TransferResult>> sendTransaction({
    required String network,
    required String rawData,
  });
}

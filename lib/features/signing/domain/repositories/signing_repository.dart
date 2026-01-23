import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sign_request.dart';

/// Signing Repository interface
abstract class SigningRepository {
  /// Sign message
  Future<Either<Failure, SignResult>> sign({
    required SignRequest request,
  });

  /// Sign typed data (EIP-712)
  Future<Either<Failure, SignResult>> signTypedData({
    required TypedDataSignRequest request,
  });

  /// Sign hash
  Future<Either<Failure, SignResult>> signHash({
    required HashSignRequest request,
  });

  /// Sign EIP-1559 transaction
  Future<Either<Failure, SignResult>> signEip1559({
    required Eip1559SignRequest request,
  });
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/signing_entities.dart';

/// Signing Repository interface
abstract class SigningRepository {
  /// Personal sign
  Future<Either<Failure, PersonalSignResult>> personalSign({
    required PersonalSignParams params,
  });

  /// Sign typed data (EIP-712)
  Future<Either<Failure, SignTypedDataResult>> signTypedData({
    required SignTypedDataParams params,
  });

  /// Sign hash
  Future<Either<Failure, SignHashResult>> signHash({
    required SignHashParams params,
  });

  /// Sign transaction
  Future<Either<Failure, SignedTransaction>> signTransaction({
    required SignTransactionParams params,
  });
}

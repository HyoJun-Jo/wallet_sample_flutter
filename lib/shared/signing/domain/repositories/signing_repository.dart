import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/signing_entities.dart';

/// Signing Repository interface
abstract class SigningRepository {
  /// Personal sign
  Future<Either<Failure, SignResult>> personalSign({
    required PersonalSignParams params,
  });

  /// Sign typed data (EIP-712)
  Future<Either<Failure, SignResult>> signTypedData({
    required SignTypedDataParams params,
  });

  /// Sign hash
  Future<Either<Failure, SignResult>> signHash({
    required SignHashParams params,
  });
}

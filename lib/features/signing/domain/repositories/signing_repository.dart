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

  /// Get nonce for address
  Future<Either<Failure, String>> getNonce({
    required String address,
    required String network,
  });

  /// Get suggested gas fees
  Future<Either<Failure, GasFeeInfo>> getSuggestedGasFees({
    required String network,
  });

  /// Estimate gas for transaction
  Future<Either<Failure, String>> estimateGas({
    required String network,
    required String from,
    required String to,
    required String value,
    required String data,
  });

  /// Send signed transaction
  Future<Either<Failure, String>> sendTransaction({
    required String network,
    required String signedTx,
  });
}

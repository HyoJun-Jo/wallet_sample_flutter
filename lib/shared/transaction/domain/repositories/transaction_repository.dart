import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction_entities.dart';

/// Transaction Repository interface
abstract class TransactionRepository {
  /// Get nonce for address
  Future<Either<Failure, String>> getNonce({
    required String address,
    required String network,
  });

  /// Get suggested gas fees (EIP-1559)
  Future<Either<Failure, GasFees>> getGasFees({
    required String network,
  });

  /// Estimate gas for transaction
  Future<Either<Failure, EstimateGasResult>> estimateGas({
    required EstimateGasParams params,
  });

  /// Sign transaction (EIP-1559)
  Future<Either<Failure, SignedTransaction>> signTransaction({
    required SignTransactionParams params,
  });

  /// Send signed transaction
  Future<Either<Failure, TransactionResult>> sendTransaction({
    required SendTransactionParams params,
  });
}

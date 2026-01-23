import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/token_info.dart';
import '../entities/transfer.dart';

/// Callback for when tokens are refreshed in background
typedef OnTokensRefreshed = void Function(List<TokenInfo> tokens);

/// Token Repository interface (matches SDK TokenRepository)
abstract class TokenRepository {
  /// Get all tokens for a wallet (cache-first strategy)
  /// Returns cached data immediately if available, then refreshes in background
  /// [networks] - comma-separated network names (e.g., "ethereum,polygon,binance")
  /// [minimalInfo] - if true, returns minimal token info (faster response)
  /// [onRefresh] is called when new data is fetched from API
  Future<Either<Failure, List<TokenInfo>>> getAllTokens({
    required String walletAddress,
    required String networks,
    bool minimalInfo = false,
    OnTokensRefreshed? onRefresh,
  });

  /// Get token allowance
  Future<Either<Failure, TokenAllowance>> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
    required String network,
  });

  /// Get transfer data (ERC-20 transfer() ABI data)
  /// Used for ERC-20 token transfers to encode the transfer function call
  Future<Either<Failure, TransferDataResult>> getTransferData({
    required GetTransferDataParams params,
  });

  /// Clear cached tokens
  Future<void> clearCache(String walletAddress);
}

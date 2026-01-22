import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/token_info.dart';
import '../repositories/token_repository.dart';

/// Get All Tokens UseCase (cache-first strategy)
class GetAllTokensUseCase implements UseCase<List<TokenInfo>, GetAllTokensParams> {
  final TokenRepository _repository;

  GetAllTokensUseCase(this._repository);

  @override
  Future<Either<Failure, List<TokenInfo>>> call(GetAllTokensParams params) {
    return _repository.getAllTokens(
      walletAddress: params.walletAddress,
      networks: params.networks,
      minimalInfo: params.minimalInfo,
      onRefresh: params.onRefresh,
    );
  }
}

class GetAllTokensParams extends Equatable {
  final String walletAddress;
  /// Comma-separated network names (e.g., "ethereum,polygon,binance")
  final String networks;
  /// If true, returns minimal token info (faster response)
  final bool minimalInfo;
  final OnTokensRefreshed? onRefresh;

  const GetAllTokensParams({
    required this.walletAddress,
    required this.networks,
    this.minimalInfo = false,
    this.onRefresh,
  });

  @override
  List<Object?> get props => [walletAddress, networks, minimalInfo];
}

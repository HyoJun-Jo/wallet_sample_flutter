import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/entities/token_transfer.dart';
import '../../domain/repositories/token_repository.dart';
import '../datasources/token_local_datasource.dart';
import '../datasources/token_remote_datasource.dart';
import '../models/token_info_model.dart';

class TokenRepositoryImpl implements TokenRepository {
  final TokenRemoteDataSource _remoteDataSource;
  final TokenLocalDataSource _localDataSource;

  TokenRepositoryImpl({
    required TokenRemoteDataSource remoteDataSource,
    required TokenLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<TokenInfo>>> getAllTokens({
    required String walletAddress,
    required String networks,
    bool minimalInfo = false,
    OnTokensRefreshed? onRefresh,
  }) async {
    try {
      final cached = await _localDataSource.getCachedTokens(walletAddress);

      if (cached != null && cached.isNotEmpty) {
        final entities = _filterAndSort(cached);

        _refreshInBackground(walletAddress, networks, minimalInfo, onRefresh);

        return Right(entities);
      }

      final tokens = await _remoteDataSource.getAllTokens(
        walletAddress: walletAddress,
        networks: networks,
        minimalInfo: minimalInfo,
      );

      await _localDataSource.cacheTokens(walletAddress, tokens);

      final entities = _filterAndSort(tokens);

      if (onRefresh != null) {
        onRefresh(entities);
      }

      return Right(entities);
    } on ServerException catch (e) {
      final cached = await _localDataSource.getCachedTokens(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        return Right(_filterAndSort(cached));
      }
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      final cached = await _localDataSource.getCachedTokens(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        return Right(_filterAndSort(cached));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _refreshInBackground(
    String walletAddress,
    String networks,
    bool minimalInfo,
    OnTokensRefreshed? onRefresh,
  ) async {
    try {
      final tokens = await _remoteDataSource.getAllTokens(
        walletAddress: walletAddress,
        networks: networks,
        minimalInfo: minimalInfo,
      );

      await _localDataSource.cacheTokens(walletAddress, tokens);

      if (onRefresh != null) {
        onRefresh(_filterAndSort(tokens));
      }
    } catch (_) {
      if (onRefresh != null) {
        final cached = await _localDataSource.getCachedTokens(walletAddress);
        if (cached != null) {
          onRefresh(_filterAndSort(cached));
        }
      }
    }
  }

  List<TokenInfo> _filterAndSort(List<TokenInfoModel> models) {
    final filtered = models.where((m) {
      if (m.possibleSpam) return false;
      if (m.isNative) return true;
      return m.hrBalance > 0;
    }).toList();

    filtered.sort((a, b) {
      final aValue = a.valueUsd ?? 0;
      final bValue = b.valueUsd ?? 0;

      if (aValue != bValue) {
        return bValue.compareTo(aValue);
      }

      return b.hrBalance.compareTo(a.hrBalance);
    });

    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> clearCache(String walletAddress) async {
    await _localDataSource.clearCachedTokens(walletAddress);
  }

  @override
  Future<Either<Failure, TokenTransferDataResult>> getTransferData({
    required GetTokenTransferDataParams params,
  }) async {
    try {
      final result = await _remoteDataSource.getTransferData(params: params);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

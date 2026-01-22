import 'dart:developer';

import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/repositories/token_repository.dart';
import '../datasources/token_local_datasource.dart';
import '../datasources/token_remote_datasource.dart';
import '../models/token_info_model.dart';

/// Token Repository implementation with cache-first strategy
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
      // 1. Try to get cached tokens first
      final cached = await _localDataSource.getCachedTokens(walletAddress);

      if (cached != null && cached.isNotEmpty) {
        // Return cached data immediately
        final filteredCached = _filterAndSortTokens(cached);

        // Refresh in background
        _refreshTokensInBackground(walletAddress, networks, minimalInfo, onRefresh);

        return Right(filteredCached);
      }

      // 2. No cache, fetch from API
      final tokens = await _remoteDataSource.getAllTokens(
        walletAddress: walletAddress,
        networks: networks,
        minimalInfo: minimalInfo,
      );

      // 3. Cache the result
      await _localDataSource.cacheTokens(walletAddress, tokens);

      final filtered = _filterAndSortTokens(tokens);

      // 4. Notify callback - data is fresh from API (not from cache)
      if (onRefresh != null) {
        onRefresh(filtered);
      }

      return Right(filtered);
    } on ServerException catch (e) {
      // If API fails but we have cache, return cache
      final cached = await _localDataSource.getCachedTokens(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        return Right(_filterAndSortTokens(cached));
      }
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      // If error but we have cache, return cache
      final cached = await _localDataSource.getCachedTokens(walletAddress);
      if (cached != null && cached.isNotEmpty) {
        return Right(_filterAndSortTokens(cached));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Refresh tokens in background and notify via callback
  Future<void> _refreshTokensInBackground(
    String walletAddress,
    String networks,
    bool minimalInfo,
    OnTokensRefreshed? onRefresh,
  ) async {
    log('Background refresh START for $walletAddress', name: 'TokenRepository');
    try {
      final tokens = await _remoteDataSource.getAllTokens(
        walletAddress: walletAddress,
        networks: networks,
        minimalInfo: minimalInfo,
      );
      log('Background refresh API SUCCESS: ${tokens.length} tokens', name: 'TokenRepository');

      // Update cache
      await _localDataSource.cacheTokens(walletAddress, tokens);

      // Notify callback with new data
      if (onRefresh != null) {
        log('Background refresh calling onRefresh', name: 'TokenRepository');
        onRefresh(_filterAndSortTokens(tokens));
      } else {
        log('Background refresh onRefresh is NULL!', name: 'TokenRepository');
      }
    } catch (e) {
      // Background refresh failed - notify with cached data to stop loading indicator
      log('Background refresh FAILED: $e', name: 'TokenRepository');
      if (onRefresh != null) {
        final cached = await _localDataSource.getCachedTokens(walletAddress);
        if (cached != null) {
          log('Background refresh calling onRefresh with cached data', name: 'TokenRepository');
          onRefresh(_filterAndSortTokens(cached));
        }
      }
    }
    log('Background refresh END', name: 'TokenRepository');
  }

  /// Filter spam tokens and sort by USD value
  List<TokenInfo> _filterAndSortTokens(List<TokenInfoModel> tokens) {
    // Filter out spam and zero-balance ERC-20 tokens
    final filtered = tokens.where((t) {
      // Always filter out spam
      if (t.possibleSpam) return false;

      // Keep native tokens even with zero balance
      if (t.isNative) return true;

      // Filter out zero-balance ERC-20 tokens
      return t.hrBalance > 0;
    }).toList();

    // Sort by USD value (highest first), then by balance
    filtered.sort((a, b) {
      final aValue = a.valueUsd ?? 0;
      final bValue = b.valueUsd ?? 0;

      if (aValue != bValue) {
        return bValue.compareTo(aValue);
      }

      // If same value, sort by balance
      return b.hrBalance.compareTo(a.hrBalance);
    });

    return filtered;
  }

  @override
  Future<Either<Failure, TokenAllowance>> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
    required String network,
  }) async {
    try {
      final result = await _remoteDataSource.getAllowance(
        contractAddress: contractAddress,
        ownerAddress: ownerAddress,
        spenderAddress: spenderAddress,
        network: network,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> clearCache(String walletAddress) async {
    await _localDataSource.clearCachedTokens(walletAddress);
  }
}

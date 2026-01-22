import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/sns_auth_repository.dart';
import '../datasources/sns_auth_datasource.dart';

class SnsAuthRepositoryImpl implements SnsAuthRepository {
  final SnsAuthDataSource _dataSource;

  SnsAuthRepositoryImpl({required SnsAuthDataSource dataSource})
      : _dataSource = dataSource;

  @override
  bool get isAppleSignInAvailable => _dataSource.isAppleSignInAvailable;

  @override
  Future<Either<Failure, SnsAuthResult?>> signIn(LoginType loginType) async {
    try {
      final result = switch (loginType) {
        LoginType.google => await _dataSource.signInWithGoogle(),
        LoginType.apple => await _dataSource.signInWithApple(),
        LoginType.kakao => await _dataSource.signInWithKakao(),
        _ => throw UnsupportedError('${loginType.name} login not supported'),
      };

      if (result == null) return const Right(null);

      return Right(SnsAuthResult(token: result.token, email: result.email));
    } on UnsupportedError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unsupported login type'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

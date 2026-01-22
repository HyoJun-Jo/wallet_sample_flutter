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
  Future<Either<Failure, SnsAuthResult?>> signIn(LoginType loginType) async {
    try {
      final result = switch (loginType) {
        LoginType.google => await _dataSource.signInWithGoogle(),
        LoginType.apple => await _dataSource.signInWithApple(),
        LoginType.kakao => await _dataSource.signInWithKakao(),
        _ => throw UnsupportedError('${loginType.name} login not supported'),
      };

      return Right(result);
    } on UnsupportedError catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unsupported login type'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

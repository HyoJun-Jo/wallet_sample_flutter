import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/auth/entities/auth_entities.dart';
import '../../../../core/auth/repositories/auth_repository.dart';

class RefreshTokenUseCase implements UseCase<AuthCredentials, NoParams> {
  final AuthRepository _repository;

  RefreshTokenUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, AuthCredentials>> call(NoParams params) async {
    final savedCredentials = await _repository.getSavedCredentials();

    return savedCredentials.fold(
      (failure) => Left(failure),
      (credentials) async {
        if (credentials == null) {
          return Left(AuthFailure(message: 'No saved credentials'));
        }
        return await _repository.refreshToken(
          refreshToken: credentials.refreshToken,
        );
      },
    );
  }
}

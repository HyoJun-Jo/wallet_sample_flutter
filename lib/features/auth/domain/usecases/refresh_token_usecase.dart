import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Token refresh use case
class RefreshTokenUseCase
    implements UseCase<AuthCredentials, RefreshTokenParams> {
  final AuthRepository _repository;

  RefreshTokenUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, AuthCredentials>> call(
      RefreshTokenParams params) async {
    return await _repository.refreshToken(
      refreshToken: params.refreshToken,
    );
  }
}

/// Token refresh parameters
class RefreshTokenParams extends Equatable {
  final String refreshToken;

  const RefreshTokenParams({
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [refreshToken];
}

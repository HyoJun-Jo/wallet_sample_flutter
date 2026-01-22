import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class InitPasswordUseCase implements UseCase<void, InitPasswordParams> {
  final AuthRepository _repository;

  InitPasswordUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(InitPasswordParams params) async {
    return await _repository.initPassword(
      email: params.email,
      password: params.password,
      code: params.code,
    );
  }
}

class InitPasswordParams extends Equatable {
  final String email;
  final String password;
  final String code;

  const InitPasswordParams({
    required this.email,
    required this.password,
    required this.code,
  });

  @override
  List<Object?> get props => [email, password, code];
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Email login use case
class EmailLoginUseCase implements UseCase<EmailLoginResult, EmailLoginParams> {
  final AuthRepository _repository;

  EmailLoginUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, EmailLoginResult>> call(EmailLoginParams params) async {
    return await _repository.loginWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

/// Email login parameters
class EmailLoginParams extends Equatable {
  final String email;
  final String password;

  const EmailLoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

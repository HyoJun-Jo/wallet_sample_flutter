import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/auth/entities/auth_entities.dart';
import '../../../../core/auth/repositories/auth_repository.dart';

class EmailLoginUseCase implements UseCase<EmailLoginResult, EmailLoginParams> {
  final AuthRepository _repository;
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  EmailLoginUseCase({
    required AuthRepository repository,
    required LocalStorageService localStorage,
    required SecureStorageService secureStorage,
  })  : _repository = repository,
        _localStorage = localStorage,
        _secureStorage = secureStorage;

  @override
  Future<Either<Failure, EmailLoginResult>> call(EmailLoginParams params) async {
    final result = await _repository.loginWithEmail(
      email: params.email,
      password: params.password,
    );

    return result.fold(
      (failure) => Left(failure),
      (loginResult) async {
        if (loginResult is EmailLoginSuccess) {
          await _repository.saveUserSession(
            email: params.email,
            loginType: LoginType.email,
          );
          await _localStorage.setBool(LocalStorageKeys.autoLogin, params.autoLogin);
          if (params.autoLogin) {
            await _secureStorage.setUserPassword(params.password);
          } else {
            await _secureStorage.deleteUserPassword();
          }
        }
        return Right(loginResult);
      },
    );
  }
}

class EmailLoginParams extends Equatable {
  final String email;
  final String password;
  final bool autoLogin;

  const EmailLoginParams({
    required this.email,
    required this.password,
    this.autoLogin = false,
  });

  @override
  List<Object?> get props => [email, password, autoLogin];
}

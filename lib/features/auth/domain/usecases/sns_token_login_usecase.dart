import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';
import '../repositories/sns_auth_repository.dart';

/// SNS token login use case
/// OAuth SDK를 통해 토큰을 획득하고 WaaS API로 인증하는 통합 UseCase
class SnsTokenLoginUseCase
    implements UseCase<SnsLoginResult, SnsTokenLoginParams> {
  final SnsAuthRepository _snsAuthRepository;
  final AuthRepository _authRepository;

  SnsTokenLoginUseCase({
    required SnsAuthRepository snsAuthRepository,
    required AuthRepository authRepository,
  })  : _snsAuthRepository = snsAuthRepository,
        _authRepository = authRepository;

  @override
  Future<Either<Failure, SnsLoginResult>> call(
      SnsTokenLoginParams params) async {
    // 1. OAuth SDK로 토큰 획득
    final snsResult = await _snsAuthRepository.signIn(params.loginType);

    return snsResult.fold(
      (failure) => Left(failure),
      (result) async {
        if (result == null) {
          return Left(AuthFailure(message: 'SNS sign-in cancelled'));
        }

        // 2. WaaS API로 인증
        final loginResult = await _authRepository.loginWithSnsToken(
          snsToken: result.token,
          snsType: params.loginType.name,
        );

        return loginResult.fold(
          (failure) => Left(failure),
          (snsLoginResult) {
            // 이메일 정보 추가 (SDK에서 받은 것 사용)
            if (snsLoginResult is SnsLoginSuccess) {
              return Right(SnsLoginSuccess(
                credentials: snsLoginResult.credentials,
                snsEmail: result.email,
              ));
            }
            return Right(snsLoginResult);
          },
        );
      },
    );
  }
}

/// SNS token login parameters
class SnsTokenLoginParams extends Equatable {
  final LoginType loginType;
  final bool autoLogin;

  const SnsTokenLoginParams({
    required this.loginType,
    this.autoLogin = false,
  });

  @override
  List<Object?> get props => [loginType, autoLogin];
}

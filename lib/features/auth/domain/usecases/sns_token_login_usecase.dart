import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';
import '../repositories/sns_auth_repository.dart';

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
    final snsResult = await _snsAuthRepository.signIn(params.loginType);

    return snsResult.fold(
      (failure) => Left(failure),
      (result) async {
        if (result == null) {
          return Left(AuthFailure(message: 'SNS sign-in cancelled'));
        }

        final loginResult = await _authRepository.loginWithSnsToken(
          snsToken: result.token,
          snsType: params.loginType.name,
        );

        return loginResult.fold(
          (failure) => Left(failure),
          (snsLoginResult) async {
            if (snsLoginResult is SnsLoginSuccess) {
              final email = result.email ??
                  _extractEmailFromToken(snsLoginResult.credentials.accessToken);
              if (email != null) {
                await _authRepository.saveUserSession(
                  email: email,
                  loginType: params.loginType,
                );
              }
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

  String? _extractEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (data['email'] != null) {
        return data['email'] as String;
      }

      if (data['preferred_username'] != null) {
        final username = data['preferred_username'] as String;
        if (username.contains('@')) {
          return username;
        }
      }

      return data['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class SnsTokenLoginParams extends Equatable {
  final LoginType loginType;

  const SnsTokenLoginParams({
    required this.loginType,
  });

  @override
  List<Object?> get props => [loginType];
}

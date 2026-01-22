import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendVerificationCodeUseCase
    implements UseCase<void, SendVerificationCodeParams> {
  final AuthRepository _repository;

  SendVerificationCodeUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(SendVerificationCodeParams params) async {
    return await _repository.sendVerificationCode(
      email: params.email,
      template: params.template,
    );
  }
}

class SendVerificationCodeParams extends Equatable {
  final String email;
  final String template;

  const SendVerificationCodeParams({
    required this.email,
    required this.template,
  });

  @override
  List<Object?> get props => [email, template];
}

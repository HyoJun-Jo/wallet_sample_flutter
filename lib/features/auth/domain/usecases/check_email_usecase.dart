import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckEmailUseCase implements UseCase<bool, String> {
  final AuthRepository _repository;

  CheckEmailUseCase({required AuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(String email) async {
    return await _repository.checkEmailAvailable(email: email);
  }
}

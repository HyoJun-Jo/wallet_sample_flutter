import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/usecases/usecase.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  final SessionManager _sessionManager;

  LogoutUseCase({required SessionManager sessionManager})
      : _sessionManager = sessionManager;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _sessionManager.logout();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

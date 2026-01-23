import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/auth/entities/auth_entities.dart';

abstract class SnsAuthRepository {
  Future<Either<Failure, SnsAuthResult?>> signIn(LoginType loginType);
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_entities.dart';

abstract class SnsAuthRepository {
  Future<Either<Failure, SnsAuthResult?>> signIn(LoginType loginType);
  Future<Either<Failure, void>> signOut();
  bool get isAppleSignInAvailable;
}

class SnsAuthResult {
  final String token;
  final String? email;

  const SnsAuthResult({required this.token, this.email});
}

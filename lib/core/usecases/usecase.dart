import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// UseCase base class
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// For cases where no parameters are needed
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}

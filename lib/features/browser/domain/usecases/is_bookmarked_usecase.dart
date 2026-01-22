import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bookmark_repository.dart';

/// Is Bookmarked UseCase
class IsBookmarkedUseCase implements UseCase<bool, IsBookmarkedParams> {
  final BookmarkRepository _repository;

  IsBookmarkedUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(IsBookmarkedParams params) {
    return _repository.isBookmarked(url: params.url);
  }
}

class IsBookmarkedParams extends Equatable {
  final String url;

  const IsBookmarkedParams({required this.url});

  @override
  List<Object?> get props => [url];
}

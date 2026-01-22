import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bookmark_repository.dart';

/// Remove Bookmark UseCase
class RemoveBookmarkUseCase implements UseCase<void, RemoveBookmarkParams> {
  final BookmarkRepository _repository;

  RemoveBookmarkUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(RemoveBookmarkParams params) {
    return _repository.removeBookmark(url: params.url);
  }
}

class RemoveBookmarkParams extends Equatable {
  final String url;

  const RemoveBookmarkParams({required this.url});

  @override
  List<Object?> get props => [url];
}

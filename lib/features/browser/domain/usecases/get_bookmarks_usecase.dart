import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

/// Get Bookmarks UseCase
class GetBookmarksUseCase implements UseCase<List<Bookmark>, NoParams> {
  final BookmarkRepository _repository;

  GetBookmarksUseCase(this._repository);

  @override
  Future<Either<Failure, List<Bookmark>>> call(NoParams params) {
    return _repository.getBookmarks();
  }
}

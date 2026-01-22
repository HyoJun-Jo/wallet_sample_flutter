import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bookmark_repository.dart';

/// Add Bookmark UseCase
class AddBookmarkUseCase implements UseCase<void, AddBookmarkParams> {
  final BookmarkRepository _repository;

  AddBookmarkUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(AddBookmarkParams params) {
    return _repository.addBookmark(
      title: params.title,
      url: params.url,
    );
  }
}

class AddBookmarkParams extends Equatable {
  final String title;
  final String url;

  const AddBookmarkParams({
    required this.title,
    required this.url,
  });

  @override
  List<Object?> get props => [title, url];
}

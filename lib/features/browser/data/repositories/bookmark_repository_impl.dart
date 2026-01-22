import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/bookmark_local_datasource.dart';
import '../models/bookmark_model.dart';

/// Bookmark Repository implementation
class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkLocalDataSource _localDataSource;

  BookmarkRepositoryImpl({required BookmarkLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<Bookmark>>> getBookmarks() async {
    try {
      final bookmarks = await _localDataSource.getBookmarks();
      return Right(bookmarks);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addBookmark({
    required String title,
    required String url,
  }) async {
    try {
      final bookmark = BookmarkModel(
        title: title,
        url: url,
        createdAt: DateTime.now(),
      );
      await _localDataSource.addBookmark(bookmark);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookmark({required String url}) async {
    try {
      await _localDataSource.removeBookmark(url);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isBookmarked({required String url}) async {
    try {
      final result = await _localDataSource.isBookmarked(url);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

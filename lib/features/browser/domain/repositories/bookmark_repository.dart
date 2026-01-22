import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bookmark.dart';

/// Bookmark Repository interface
abstract class BookmarkRepository {
  /// Get all bookmarks
  Future<Either<Failure, List<Bookmark>>> getBookmarks();

  /// Add a bookmark
  Future<Either<Failure, void>> addBookmark({
    required String title,
    required String url,
  });

  /// Remove a bookmark by URL
  Future<Either<Failure, void>> removeBookmark({required String url});

  /// Check if URL is bookmarked
  Future<Either<Failure, bool>> isBookmarked({required String url});
}

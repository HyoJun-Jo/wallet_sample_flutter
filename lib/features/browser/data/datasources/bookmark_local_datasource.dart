import 'dart:convert';
import '../../../../core/storage/local_storage.dart';
import '../models/bookmark_model.dart';

/// Bookmark local data source interface
abstract class BookmarkLocalDataSource {
  /// Get all bookmarks
  Future<List<BookmarkModel>> getBookmarks();

  /// Add a bookmark
  Future<void> addBookmark(BookmarkModel bookmark);

  /// Remove a bookmark by URL
  Future<void> removeBookmark(String url);

  /// Check if URL is bookmarked
  Future<bool> isBookmarked(String url);
}

/// Bookmark local data source implementation
class BookmarkLocalDataSourceImpl implements BookmarkLocalDataSource {
  final LocalStorageService _localStorage;

  static const String _bookmarkKey = 'web3_browser_bookmarks';

  BookmarkLocalDataSourceImpl({required LocalStorageService localStorage})
      : _localStorage = localStorage;

  @override
  Future<List<BookmarkModel>> getBookmarks() async {
    final jsonString = _localStorage.getString(_bookmarkKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => BookmarkModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addBookmark(BookmarkModel bookmark) async {
    final bookmarks = await getBookmarks();

    // Check if already exists
    if (bookmarks.any((b) => b.url == bookmark.url)) {
      return;
    }

    bookmarks.add(bookmark);
    await _saveBookmarks(bookmarks);
  }

  @override
  Future<void> removeBookmark(String url) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.url == url);
    await _saveBookmarks(bookmarks);
  }

  @override
  Future<bool> isBookmarked(String url) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.url == url);
  }

  Future<void> _saveBookmarks(List<BookmarkModel> bookmarks) async {
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _localStorage.setString(_bookmarkKey, jsonString);
  }
}

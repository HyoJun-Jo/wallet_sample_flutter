import 'package:equatable/equatable.dart';

import '../../domain/entities/bookmark.dart';

enum BrowserStatus { initial, loading, loaded, error }

/// Browser state
class BrowserState extends Equatable {
  final BrowserStatus status;
  final String currentUrl;
  final String? pageTitle;
  final bool isLoading;
  final int loadingProgress;
  final bool canGoBack;
  final bool canGoForward;
  final List<Bookmark> bookmarks;
  final bool isCurrentPageBookmarked;
  final String? errorMessage;

  const BrowserState({
    this.status = BrowserStatus.initial,
    this.currentUrl = '',
    this.pageTitle,
    this.isLoading = false,
    this.loadingProgress = 0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.bookmarks = const [],
    this.isCurrentPageBookmarked = false,
    this.errorMessage,
  });

  BrowserState copyWith({
    BrowserStatus? status,
    String? currentUrl,
    String? pageTitle,
    bool? isLoading,
    int? loadingProgress,
    bool? canGoBack,
    bool? canGoForward,
    List<Bookmark>? bookmarks,
    bool? isCurrentPageBookmarked,
    String? errorMessage,
  }) {
    return BrowserState(
      status: status ?? this.status,
      currentUrl: currentUrl ?? this.currentUrl,
      pageTitle: pageTitle ?? this.pageTitle,
      isLoading: isLoading ?? this.isLoading,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      bookmarks: bookmarks ?? this.bookmarks,
      isCurrentPageBookmarked: isCurrentPageBookmarked ?? this.isCurrentPageBookmarked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentUrl,
        pageTitle,
        isLoading,
        loadingProgress,
        canGoBack,
        canGoForward,
        bookmarks,
        isCurrentPageBookmarked,
        errorMessage,
      ];
}

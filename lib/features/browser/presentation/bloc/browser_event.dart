import 'package:equatable/equatable.dart';

/// Browser event base class
sealed class BrowserEvent extends Equatable {
  const BrowserEvent();

  @override
  List<Object?> get props => [];
}

// Navigation Events

/// URL load request
class BrowserUrlLoaded extends BrowserEvent {
  final String url;

  const BrowserUrlLoaded({required this.url});

  @override
  List<Object?> get props => [url];
}

/// Page loading started
class BrowserLoadingStarted extends BrowserEvent {
  const BrowserLoadingStarted();
}

/// Page loading finished
class BrowserPageLoaded extends BrowserEvent {
  final String url;
  final String? title;
  final bool canGoBack;
  final bool canGoForward;

  const BrowserPageLoaded({
    required this.url,
    this.title,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  @override
  List<Object?> get props => [url, title, canGoBack, canGoForward];
}

/// Progress changed
class BrowserProgressChanged extends BrowserEvent {
  final int progress;

  const BrowserProgressChanged({required this.progress});

  @override
  List<Object?> get props => [progress];
}

// Bookmark Events

/// Load bookmarks
class BookmarksLoadRequested extends BrowserEvent {
  const BookmarksLoadRequested();
}

/// Add bookmark
class BookmarkAddRequested extends BrowserEvent {
  final String title;
  final String url;

  const BookmarkAddRequested({
    required this.title,
    required this.url,
  });

  @override
  List<Object?> get props => [title, url];
}

/// Remove bookmark
class BookmarkRemoveRequested extends BrowserEvent {
  final String url;

  const BookmarkRemoveRequested({required this.url});

  @override
  List<Object?> get props => [url];
}

/// Check if bookmarked
class BookmarkCheckRequested extends BrowserEvent {
  final String url;

  const BookmarkCheckRequested({required this.url});

  @override
  List<Object?> get props => [url];
}

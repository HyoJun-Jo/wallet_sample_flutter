import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_bookmark_usecase.dart';
import '../../domain/usecases/get_bookmarks_usecase.dart';
import '../../domain/usecases/is_bookmarked_usecase.dart';
import '../../domain/usecases/remove_bookmark_usecase.dart';
import 'browser_event.dart';
import 'browser_state.dart';

/// Browser BLoC
class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  final GetBookmarksUseCase _getBookmarksUseCase;
  final AddBookmarkUseCase _addBookmarkUseCase;
  final RemoveBookmarkUseCase _removeBookmarkUseCase;
  final IsBookmarkedUseCase _isBookmarkedUseCase;

  BrowserBloc({
    required GetBookmarksUseCase getBookmarksUseCase,
    required AddBookmarkUseCase addBookmarkUseCase,
    required RemoveBookmarkUseCase removeBookmarkUseCase,
    required IsBookmarkedUseCase isBookmarkedUseCase,
  })  : _getBookmarksUseCase = getBookmarksUseCase,
        _addBookmarkUseCase = addBookmarkUseCase,
        _removeBookmarkUseCase = removeBookmarkUseCase,
        _isBookmarkedUseCase = isBookmarkedUseCase,
        super(const BrowserState()) {
    on<BrowserUrlLoaded>(_onUrlLoaded);
    on<BrowserLoadingStarted>(_onLoadingStarted);
    on<BrowserPageLoaded>(_onPageLoaded);
    on<BrowserProgressChanged>(_onProgressChanged);
    on<BookmarksLoadRequested>(_onBookmarksLoadRequested);
    on<BookmarkAddRequested>(_onBookmarkAddRequested);
    on<BookmarkRemoveRequested>(_onBookmarkRemoveRequested);
    on<BookmarkCheckRequested>(_onBookmarkCheckRequested);
  }

  void _onUrlLoaded(
    BrowserUrlLoaded event,
    Emitter<BrowserState> emit,
  ) {
    if (event.url.isEmpty) {
      emit(state.copyWith(
        status: BrowserStatus.initial,
        currentUrl: '',
        pageTitle: null,
      ));
      return;
    }

    emit(state.copyWith(
      currentUrl: event.url,
      isLoading: true,
    ));
  }

  void _onLoadingStarted(
    BrowserLoadingStarted event,
    Emitter<BrowserState> emit,
  ) {
    emit(state.copyWith(
      isLoading: true,
      loadingProgress: 0,
    ));
  }

  Future<void> _onPageLoaded(
    BrowserPageLoaded event,
    Emitter<BrowserState> emit,
  ) async {
    emit(state.copyWith(
      status: BrowserStatus.loaded,
      currentUrl: event.url,
      pageTitle: event.title,
      isLoading: false,
      loadingProgress: 100,
      canGoBack: event.canGoBack,
      canGoForward: event.canGoForward,
    ));

    // Check if current page is bookmarked
    add(BookmarkCheckRequested(url: event.url));
  }

  void _onProgressChanged(
    BrowserProgressChanged event,
    Emitter<BrowserState> emit,
  ) {
    emit(state.copyWith(
      loadingProgress: event.progress,
      isLoading: event.progress < 100,
    ));
  }

  Future<void> _onBookmarksLoadRequested(
    BookmarksLoadRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final result = await _getBookmarksUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (bookmarks) => emit(state.copyWith(
        bookmarks: bookmarks,
      )),
    );
  }

  Future<void> _onBookmarkAddRequested(
    BookmarkAddRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final result = await _addBookmarkUseCase(
      AddBookmarkParams(title: event.title, url: event.url),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(isCurrentPageBookmarked: true));
        add(const BookmarksLoadRequested());
      },
    );
  }

  Future<void> _onBookmarkRemoveRequested(
    BookmarkRemoveRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final result = await _removeBookmarkUseCase(
      RemoveBookmarkParams(url: event.url),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (_) {
        if (event.url == state.currentUrl) {
          emit(state.copyWith(isCurrentPageBookmarked: false));
        }
        add(const BookmarksLoadRequested());
      },
    );
  }

  Future<void> _onBookmarkCheckRequested(
    BookmarkCheckRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final result = await _isBookmarkedUseCase(
      IsBookmarkedParams(url: event.url),
    );

    result.fold(
      (failure) => null,
      (isBookmarked) => emit(state.copyWith(
        isCurrentPageBookmarked: isBookmarked,
      )),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'browser_event.dart';
import 'browser_state.dart';

/// Browser BLoC
class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  BrowserBloc() : super(const BrowserInitial()) {
    on<BrowserLoadUrl>(_onLoadUrl);
    on<BrowserLoadingStarted>(_onLoadingStarted);
    on<BrowserLoadingFinished>(_onLoadingFinished);
    on<BrowserGoBack>(_onGoBack);
    on<BrowserGoForward>(_onGoForward);
    on<BrowserRefresh>(_onRefresh);
    on<BrowserWeb3Request>(_onWeb3Request);
  }

  void _onLoadUrl(
    BrowserLoadUrl event,
    Emitter<BrowserState> emit,
  ) {
    if (event.url.isEmpty) {
      emit(const BrowserInitial());
      return;
    }
    // Directly emit BrowserLoaded since we're using placeholder WebView
    // In production with real WebView, this should emit BrowserLoading
    // and WebView's onPageFinished callback should emit BrowserLoaded
    emit(BrowserLoaded(
      url: event.url,
      title: null,
      canGoBack: true,
      canGoForward: false,
    ));
  }

  void _onLoadingStarted(
    BrowserLoadingStarted event,
    Emitter<BrowserState> emit,
  ) {
    final currentState = state;
    if (currentState is BrowserLoaded) {
      emit(BrowserLoading(url: currentState.url));
    }
  }

  void _onLoadingFinished(
    BrowserLoadingFinished event,
    Emitter<BrowserState> emit,
  ) {
    emit(BrowserLoaded(
      url: event.url,
      title: event.title,
      canGoBack: true,
      canGoForward: false,
    ));
  }

  void _onGoBack(
    BrowserGoBack event,
    Emitter<BrowserState> emit,
  ) {
    // Navigation is handled by WebViewController
    // This event is for state tracking if needed
  }

  void _onGoForward(
    BrowserGoForward event,
    Emitter<BrowserState> emit,
  ) {
    // Navigation is handled by WebViewController
    // This event is for state tracking if needed
  }

  void _onRefresh(
    BrowserRefresh event,
    Emitter<BrowserState> emit,
  ) {
    // Refresh is handled by WebViewController
    // This event is for state tracking if needed
  }

  void _onWeb3Request(
    BrowserWeb3Request event,
    Emitter<BrowserState> emit,
  ) {
    final currentState = state;
    if (currentState is BrowserLoaded) {
      emit(BrowserWeb3RequestPending(
        method: event.method,
        params: event.params,
        previousState: currentState,
      ));
    }
  }
}

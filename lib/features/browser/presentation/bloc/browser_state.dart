import 'package:equatable/equatable.dart';

/// Browser state base class
abstract class BrowserState extends Equatable {
  const BrowserState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BrowserInitial extends BrowserState {
  const BrowserInitial();
}

/// Loading state
class BrowserLoading extends BrowserState {
  final String url;

  const BrowserLoading({required this.url});

  @override
  List<Object?> get props => [url];
}

/// Loaded state
class BrowserLoaded extends BrowserState {
  final String url;
  final String? title;
  final bool canGoBack;
  final bool canGoForward;

  const BrowserLoaded({
    required this.url,
    this.title,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  @override
  List<Object?> get props => [url, title, canGoBack, canGoForward];
}

/// Web3 request pending
class BrowserWeb3RequestPending extends BrowserState {
  final String method;
  final Map<String, dynamic>? params;
  final BrowserLoaded previousState;

  const BrowserWeb3RequestPending({
    required this.method,
    this.params,
    required this.previousState,
  });

  @override
  List<Object?> get props => [method, params, previousState];
}

/// Error state
class BrowserError extends BrowserState {
  final String message;

  const BrowserError({required this.message});

  @override
  List<Object?> get props => [message];
}

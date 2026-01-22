import 'package:equatable/equatable.dart';

/// Browser event base class
abstract class BrowserEvent extends Equatable {
  const BrowserEvent();

  @override
  List<Object?> get props => [];
}

/// URL load request
class BrowserLoadUrl extends BrowserEvent {
  final String url;

  const BrowserLoadUrl({required this.url});

  @override
  List<Object?> get props => [url];
}

/// Page loading started
class BrowserLoadingStarted extends BrowserEvent {
  const BrowserLoadingStarted();
}

/// Page loading finished
class BrowserLoadingFinished extends BrowserEvent {
  final String url;
  final String? title;

  const BrowserLoadingFinished({required this.url, this.title});

  @override
  List<Object?> get props => [url, title];
}

/// Go back request
class BrowserGoBack extends BrowserEvent {
  const BrowserGoBack();
}

/// Go forward request
class BrowserGoForward extends BrowserEvent {
  const BrowserGoForward();
}

/// Refresh request
class BrowserRefresh extends BrowserEvent {
  const BrowserRefresh();
}

/// Web3 request received
class BrowserWeb3Request extends BrowserEvent {
  final String method;
  final Map<String, dynamic>? params;

  const BrowserWeb3Request({required this.method, this.params});

  @override
  List<Object?> get props => [method, params];
}

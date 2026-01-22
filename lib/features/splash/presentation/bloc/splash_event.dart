import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Check app initialization status (auto login, wallet existence)
class SplashCheckRequested extends SplashEvent {
  const SplashCheckRequested();
}

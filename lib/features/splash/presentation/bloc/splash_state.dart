import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// Initial state - showing splash logo
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Checking authentication and wallet status
class SplashChecking extends SplashState {
  const SplashChecking();
}

/// Navigate to login page (no valid token)
class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

/// Navigate to wallet creation page (has token but no wallet)
class SplashNavigateToWalletCreate extends SplashState {
  const SplashNavigateToWalletCreate();
}

/// Navigate to main page (has token and wallet)
class SplashNavigateToMain extends SplashState {
  final String walletAddress;

  const SplashNavigateToMain({required this.walletAddress});

  @override
  List<Object?> get props => [walletAddress];
}

/// Error occurred during initialization
class SplashError extends SplashState {
  final String message;

  const SplashError({required this.message});

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../../shared/wallet/domain/entities/wallet_credentials.dart';

/// Wallet state base class
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Loading state
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Wallet credentials loaded
class WalletLoaded extends WalletState {
  final WalletCredentials? credentials;

  const WalletLoaded({this.credentials});

  @override
  List<Object?> get props => [credentials];
}

/// Wallet created
class WalletCreated extends WalletState {
  final WalletCredentials credentials;

  const WalletCreated({required this.credentials});

  @override
  List<Object?> get props => [credentials];
}

/// Wallet deleted
class WalletDeleted extends WalletState {
  const WalletDeleted();
}

/// Error state
class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}

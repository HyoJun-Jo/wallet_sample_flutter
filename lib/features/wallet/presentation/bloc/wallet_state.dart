import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet.dart';

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

/// Wallet list loaded
class WalletListLoaded extends WalletState {
  final List<Wallet> wallets;

  const WalletListLoaded({required this.wallets});

  @override
  List<Object?> get props => [wallets];
}

/// Wallet created
class WalletCreated extends WalletState {
  final WalletCreateResult result;

  const WalletCreated({required this.result});

  @override
  List<Object?> get props => [result];
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

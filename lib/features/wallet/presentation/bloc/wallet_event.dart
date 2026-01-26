import 'package:equatable/equatable.dart';

/// Wallet event base class
abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load wallet credentials
class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

/// Request to create wallet
class WalletCreateRequested extends WalletEvent {
  final String email;
  final String password;

  const WalletCreateRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Request to delete wallet
class WalletDeleteRequested extends WalletEvent {
  final String address;

  const WalletDeleteRequested({required this.address});

  @override
  List<Object?> get props => [address];
}

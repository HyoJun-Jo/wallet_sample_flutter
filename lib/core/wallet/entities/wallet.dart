import 'package:equatable/equatable.dart';

/// Wallet entity
class Wallet extends Equatable {
  final String address;
  final String? name;
  final String network;
  final DateTime createdAt;
  final String? solanaAddress;

  const Wallet({
    required this.address,
    this.name,
    required this.network,
    required this.createdAt,
    this.solanaAddress,
  });

  @override
  List<Object?> get props => [address, name, network, createdAt, solanaAddress];
}

/// Wallet creation result
class WalletCreateResult extends Equatable {
  final String address;
  final String keyShare;

  const WalletCreateResult({
    required this.address,
    required this.keyShare,
  });

  @override
  List<Object?> get props => [address, keyShare];
}

/// Wallet recovery status
enum WalletRecoveryStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Wallet credentials for signing operations
/// Contains all information needed to perform wallet signing
class WalletCredentials extends Equatable {
  final String address;
  final String keyShare;
  final String uid;
  final int wid;
  final String encDevicePassword;

  const WalletCredentials({
    required this.address,
    required this.keyShare,
    required this.uid,
    required this.wid,
    required this.encDevicePassword,
  });

  @override
  List<Object?> get props => [address, keyShare, uid, wid, encDevicePassword];
}

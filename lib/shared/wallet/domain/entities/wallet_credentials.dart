import 'package:equatable/equatable.dart';

import '../../data/models/wallet_create_model.dart';

/// Wallet credentials for all chains
class WalletCredentials extends Equatable {
  // EVM
  final String address;
  final String keyShare;
  final String uid;
  final int wid;
  final String encDevicePassword;

  // BTC
  final String? btcAddress;

  // Solana
  final String? solAddress;
  final Ed25519KeyShareInfoModel? ed25519KeyShareInfo;

  const WalletCredentials({
    required this.address,
    required this.keyShare,
    required this.uid,
    required this.wid,
    required this.encDevicePassword,
    this.btcAddress,
    this.solAddress,
    this.ed25519KeyShareInfo,
  });

  WalletCredentials copyWith({
    String? address,
    String? keyShare,
    String? uid,
    int? wid,
    String? encDevicePassword,
    String? btcAddress,
    String? solAddress,
    Ed25519KeyShareInfoModel? ed25519KeyShareInfo,
  }) {
    return WalletCredentials(
      address: address ?? this.address,
      keyShare: keyShare ?? this.keyShare,
      uid: uid ?? this.uid,
      wid: wid ?? this.wid,
      encDevicePassword: encDevicePassword ?? this.encDevicePassword,
      btcAddress: btcAddress ?? this.btcAddress,
      solAddress: solAddress ?? this.solAddress,
      ed25519KeyShareInfo: ed25519KeyShareInfo ?? this.ed25519KeyShareInfo,
    );
  }

  @override
  List<Object?> get props => [
        address,
        keyShare,
        uid,
        wid,
        encDevicePassword,
        btcAddress,
        solAddress,
        ed25519KeyShareInfo,
      ];
}

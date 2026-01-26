import 'dart:convert';

import '../../domain/entities/wallet_credentials.dart';
import 'wallet_create_response_model.dart';

/// Wallet credentials model - 모든 지갑 정보 + 서명 정보
class WalletCreateModel {
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

  const WalletCreateModel({
    required this.address,
    required this.keyShare,
    required this.uid,
    required this.wid,
    required this.encDevicePassword,
    this.btcAddress,
    this.solAddress,
    this.ed25519KeyShareInfo,
  });

  /// API 필드명 호환 (signing API에서 사용)
  String get sid => address;
  String get pvencstr => keyShare;

  /// From API response model
  factory WalletCreateModel.fromResponse(WalletCreateResponseModel response) {
    return WalletCreateModel(
      address: response.address,
      keyShare: response.keyShare,
      uid: response.uid,
      wid: response.wid,
      encDevicePassword: response.encryptDevicePassword,
    );
  }

  /// From stored JSON
  factory WalletCreateModel.fromJson(Map<String, dynamic> json) {
    return WalletCreateModel(
      address: json['address'] as String,
      keyShare: json['keyShare'] as String,
      uid: json['uid'] as String,
      wid: json['wid'] as int,
      encDevicePassword: json['encDevicePassword'] as String,
      btcAddress: json['btcAddress'] as String?,
      solAddress: json['solAddress'] as String?,
      ed25519KeyShareInfo: json['ed25519KeyShareInfo'] != null
          ? Ed25519KeyShareInfoModel.fromJson(
              json['ed25519KeyShareInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  static WalletCreateModel? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return WalletCreateModel.fromJson(
        Map<String, dynamic>.from(
          const JsonDecoder().convert(jsonString) as Map,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'keyShare': keyShare,
      'uid': uid,
      'wid': wid,
      'encDevicePassword': encDevicePassword,
      'btcAddress': btcAddress,
      'solAddress': solAddress,
      'ed25519KeyShareInfo': ed25519KeyShareInfo?.toJson(),
    };
  }

  String toJsonString() => const JsonEncoder().convert(toJson());

  WalletCreateModel copyWith({
    String? address,
    String? keyShare,
    String? uid,
    int? wid,
    String? encDevicePassword,
    String? btcAddress,
    String? solAddress,
    Ed25519KeyShareInfoModel? ed25519KeyShareInfo,
  }) {
    return WalletCreateModel(
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

  WalletCredentials toEntity() {
    return WalletCredentials(
      address: address,
      keyShare: keyShare,
      uid: uid,
      wid: wid,
      encDevicePassword: encDevicePassword,
      btcAddress: btcAddress,
      solAddress: solAddress,
      ed25519KeyShareInfo: ed25519KeyShareInfo,
    );
  }
}

/// ED25519 KeyShare model (for Solana signing)
class Ed25519KeyShareInfoModel {
  final String curve;
  final String encryptedShare;
  final String keyId;
  final String publicKey;
  final String secretStore;

  const Ed25519KeyShareInfoModel({
    required this.curve,
    required this.encryptedShare,
    required this.keyId,
    required this.publicKey,
    required this.secretStore,
  });

  factory Ed25519KeyShareInfoModel.fromJson(Map<String, dynamic> json) {
    return Ed25519KeyShareInfoModel(
      curve: json['curve'] as String,
      encryptedShare: json['encrypted_share'] as String,
      keyId: json['key_id'] as String,
      publicKey: json['public_key'] as String,
      secretStore: json['secret_store'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curve': curve,
      'encrypted_share': encryptedShare,
      'key_id': keyId,
      'public_key': publicKey,
      'secret_store': secretStore,
    };
  }
}

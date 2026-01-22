import 'dart:convert';

import '../../domain/entities/wallet.dart';

/// Wallet model for local storage
class WalletModel extends Wallet {
  const WalletModel({
    required super.address,
    super.name,
    required super.network,
    required super.createdAt,
    super.solanaAddress,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      address: json['address'] as String,
      name: json['name'] as String?,
      network: json['network'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      solanaAddress: json['solana_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'network': network,
      'created_at': createdAt.toIso8601String(),
      'solana_address': solanaAddress,
    };
  }
}

/// Wallet creation result model (POST /wallet-v2 response)
/// Used for storing/restoring wallet credentials for signing
class WalletCreateResultModel extends WalletCreateResult {
  final String uid;
  final int wid;
  final String encDevicePassword;

  const WalletCreateResultModel({
    required super.address,
    required super.keyShare,
    required this.uid,
    required this.wid,
    required this.encDevicePassword,
  });

  factory WalletCreateResultModel.fromJson(Map<String, dynamic> json) {
    return WalletCreateResultModel(
      address: json['sid'] as String,
      keyShare: json['pvencstr'] as String,
      uid: json['uid'] as String,
      wid: json['wid'] as int,
      encDevicePassword: json['encryptDevicePassword'] as String,
    );
  }

  static WalletCreateResultModel? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return WalletCreateResultModel.fromJson(
        Map<String, dynamic>.from(
          const JsonDecoder().convert(jsonString) as Map,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  String get sid => address;
  String get pvencstr => keyShare;

  Map<String, dynamic> toJson() {
    return {
      'sid': address,
      'pvencstr': keyShare,
      'uid': uid,
      'wid': wid,
      'encryptDevicePassword': encDevicePassword,
    };
  }

  String toJsonString() => const JsonEncoder().convert(toJson());

  /// Convert to WalletCredentials entity
  WalletCredentials toCredentialsEntity() {
    return WalletCredentials(
      address: address,
      keyShare: keyShare,
      uid: uid,
      wid: wid,
      encDevicePassword: encDevicePassword,
    );
  }
}

/// Wallet Info model (GET /wapi/v2/mpc/wallets/info response)
class WalletInfoModel {
  final String id;
  final String uid;
  final int wid;
  final String email;
  final List<WalletAccountModel> accounts;

  const WalletInfoModel({
    required this.id,
    required this.uid,
    required this.wid,
    required this.email,
    required this.accounts,
  });

  factory WalletInfoModel.fromJson(Map<String, dynamic> json) {
    return WalletInfoModel(
      id: json['_id'] as String? ?? '',
      uid: json['uid'] as String,
      wid: json['wid'] as int,
      email: json['email'] as String? ?? '',
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((item) => WalletAccountModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  WalletAccountModel? get primaryAccount => accounts.isNotEmpty ? accounts.first : null;
  String? get sid => primaryAccount?.sid;
}

/// Wallet Account model
class WalletAccountModel {
  final String id;
  final String sid;
  final String ethAddress;
  final String name;
  final String signer;
  final String? pubkey;

  const WalletAccountModel({
    required this.id,
    required this.sid,
    required this.ethAddress,
    required this.name,
    required this.signer,
    this.pubkey,
  });

  factory WalletAccountModel.fromJson(Map<String, dynamic> json) {
    return WalletAccountModel(
      id: json['id'] as String? ?? '0',
      sid: json['sid'] as String,
      ethAddress: json['ethAddress'] as String,
      name: json['name'] as String? ?? 'Account',
      signer: json['signer'] as String? ?? 'mpc',
      pubkey: json['pubkey'] as String?,
    );
  }
}

/// V3 Wallet Info model (GET /v3/wallet response)
class WalletV3InfoModel {
  final String userId;
  final List<WalletV3ItemModel> wallets;

  const WalletV3InfoModel({
    required this.userId,
    required this.wallets,
  });

  factory WalletV3InfoModel.fromJson(Map<String, dynamic> json) {
    return WalletV3InfoModel(
      userId: json['user_id'] as String,
      wallets: (json['wallets'] as List<dynamic>)
          .map((item) => WalletV3ItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  WalletV3ItemModel? findByCurve(String curve) {
    try {
      return wallets.firstWhere((w) => w.curve == curve);
    } catch (_) {
      return null;
    }
  }

  bool get hasEd25519 => wallets.any((w) => w.curve == 'ed25519');
  bool get hasSecp256k1 => wallets.any((w) => w.curve == 'secp256k1');
}

/// V3 Wallet Item model
class WalletV3ItemModel {
  final String curve;
  final String publicKey;
  final Map<String, String> addresses;

  const WalletV3ItemModel({
    required this.curve,
    required this.publicKey,
    required this.addresses,
  });

  factory WalletV3ItemModel.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as Map<String, dynamic>;
    final address = json['address'] as Map<String, dynamic>;

    return WalletV3ItemModel(
      curve: key['curve'] as String,
      publicKey: key['public_key'] as String,
      addresses: address.map((k, v) => MapEntry(k, v as String)),
    );
  }

  String? get solanaAddress => addresses['solana'];
  String? get evmAddress => addresses['evm'];
  String? get btcAddress => addresses['btc'];
  String? get aptosAddress => addresses['aptos'];
}

/// V3 KeyShare model (generate/recover response)
class WalletV3KeyShareModel {
  final String keyId;
  final String encryptedShare;
  final String secretStore;
  final String curve;
  final String publicKey;

  const WalletV3KeyShareModel({
    required this.keyId,
    required this.encryptedShare,
    required this.secretStore,
    required this.curve,
    required this.publicKey,
  });

  factory WalletV3KeyShareModel.fromJson(Map<String, dynamic> json) {
    return WalletV3KeyShareModel(
      keyId: json['key_id'] as String,
      encryptedShare: json['encrypted_share'] as String,
      secretStore: json['secret_store'] as String,
      curve: json['curve'] as String,
      publicKey: json['public_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key_id': keyId,
      'encrypted_share': encryptedShare,
      'secret_store': secretStore,
      'curve': curve,
      'public_key': publicKey,
    };
  }
}

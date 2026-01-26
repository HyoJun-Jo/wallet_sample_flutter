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

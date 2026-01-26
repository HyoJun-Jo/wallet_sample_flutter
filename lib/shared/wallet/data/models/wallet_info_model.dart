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

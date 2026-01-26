/// EVM Wallet creation API response (POST /wallet-v2)
class WalletCreateResponseModel {
  final String sid;
  final String pvencstr;
  final String uid;
  final int wid;
  final String encryptDevicePassword;

  const WalletCreateResponseModel({
    required this.sid,
    required this.pvencstr,
    required this.uid,
    required this.wid,
    required this.encryptDevicePassword,
  });

  factory WalletCreateResponseModel.fromJson(Map<String, dynamic> json) {
    return WalletCreateResponseModel(
      sid: json['sid'] as String,
      pvencstr: json['pvencstr'] as String,
      uid: json['uid'] as String,
      wid: json['wid'] as int,
      encryptDevicePassword: json['encryptDevicePassword'] as String,
    );
  }

  /// EVM 주소
  String get address => sid;

  /// EVM keyShare
  String get keyShare => pvencstr;
}

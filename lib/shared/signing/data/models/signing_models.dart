import '../../domain/entities/signing_entities.dart';

/// Sign result model
class SignResultModel extends SignResult {
  const SignResultModel({
    required super.signature,
    super.txHash,
    super.serializedTx,
    super.rawTx,
  });

  factory SignResultModel.fromJson(Map<String, dynamic> json) {
    return SignResultModel(
      // For typed-data signing, signature is in serializedTx
      signature: json['signature'] as String? ??
                 json['serializedTx'] as String? ??
                 json['rawTx'] as String? ?? '',
      txHash: json['tx_hash'] as String? ?? json['txHash'] as String?,
      serializedTx: json['serialized_tx'] as String? ?? json['serializedTx'] as String?,
      rawTx: json['raw_tx'] as String? ?? json['rawTx'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      'tx_hash': txHash,
      'serialized_tx': serializedTx,
      'raw_tx': rawTx,
    };
  }
}

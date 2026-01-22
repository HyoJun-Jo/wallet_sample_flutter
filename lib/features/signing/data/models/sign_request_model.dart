import '../../domain/entities/sign_request.dart';

/// Pre-sign result model
class PreSignResultModel extends PreSignResult {
  const PreSignResultModel({
    required super.signId,
    required super.hashToSign,
    required super.mpcPublicKey,
  });

  factory PreSignResultModel.fromJson(Map<String, dynamic> json) {
    return PreSignResultModel(
      signId: json['sign_id'] as String,
      hashToSign: json['hash_to_sign'] as String,
      mpcPublicKey: json['mpc_public_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sign_id': signId,
      'hash_to_sign': hashToSign,
      'mpc_public_key': mpcPublicKey,
    };
  }
}

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

/// Gas Fee Info model
class GasFeeInfoModel extends GasFeeInfo {
  const GasFeeInfoModel({
    required super.gasPrice,
    super.maxFeePerGas,
    super.maxPriorityFeePerGas,
    required super.estimatedGas,
  });

  factory GasFeeInfoModel.fromJson(Map<String, dynamic> json) {
    return GasFeeInfoModel(
      gasPrice: json['gas_price'] as String? ?? json['gasPrice'] as String? ?? '0',
      maxFeePerGas: json['max_fee_per_gas'] as String? ?? json['maxFeePerGas'] as String?,
      maxPriorityFeePerGas: json['max_priority_fee_per_gas'] as String? ?? json['maxPriorityFeePerGas'] as String?,
      estimatedGas: json['estimated_gas'] as String? ?? json['gas'] as String? ?? '21000',
    );
  }

  /// Create from suggestedGasFees API response
  factory GasFeeInfoModel.fromSuggestedGasFees(Map<String, dynamic> json, String estimatedGas) {
    final medium = json['medium'] as Map<String, dynamic>? ?? {};
    return GasFeeInfoModel(
      gasPrice: medium['suggestedMaxFeePerGas'] as String? ?? '0',
      maxFeePerGas: medium['suggestedMaxFeePerGas'] as String?,
      maxPriorityFeePerGas: medium['suggestedMaxPriorityFeePerGas'] as String?,
      estimatedGas: estimatedGas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gas_price': gasPrice,
      'max_fee_per_gas': maxFeePerGas,
      'max_priority_fee_per_gas': maxPriorityFeePerGas,
      'estimated_gas': estimatedGas,
    };
  }
}

import '../../domain/entities/transfer.dart';

/// Transfer data model (EIP-1559)
class TransferDataModel extends TransferData {
  const TransferDataModel({
    required super.to,
    required super.from,
    required super.data,
    required super.value,
    required super.gasLimit,
    required super.maxFeePerGas,
    required super.maxPriorityFeePerGas,
    required super.nonce,
    required super.network,
  });

  factory TransferDataModel.fromJson(Map<String, dynamic> json) {
    return TransferDataModel(
      to: json['to'] as String,
      from: json['from'] as String,
      data: json['data'] as String,
      value: json['value'] as String? ?? '0',
      gasLimit: json['gasLimit'] as String,
      maxFeePerGas: json['maxFeePerGas'] as String,
      maxPriorityFeePerGas: json['maxPriorityFeePerGas'] as String,
      nonce: json['nonce'] as String,
      network: json['network'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'from': from,
      'data': data,
      'value': value,
      'gasLimit': gasLimit,
      'maxFeePerGas': maxFeePerGas,
      'maxPriorityFeePerGas': maxPriorityFeePerGas,
      'nonce': nonce,
      'network': network,
    };
  }
}

/// Transfer result model (matches SDK - only transactionHash)
class TransferResultModel extends TransferResult {
  const TransferResultModel({
    required super.transactionHash,
  });

  factory TransferResultModel.fromJson(Map<String, dynamic> json) {
    // API returns { "tx_hash": "0x..." }
    return TransferResultModel(
      transactionHash: json['tx_hash'] as String? ?? json['transactionHash'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionHash': transactionHash,
    };
  }
}

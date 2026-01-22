import '../../domain/entities/transfer.dart';

/// Transfer request model
class TransferRequestModel extends TransferRequest {
  const TransferRequestModel({
    required super.fromAddress,
    required super.toAddress,
    required super.amount,
    required super.contractAddress,
    required super.network,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': fromAddress,
      'to': toAddress,
      'amount': amount,
      'contract_address': contractAddress,
      'network': network,
    };
  }
}

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

/// Transfer result model
class TransferResultModel extends TransferResult {
  const TransferResultModel({
    required super.txHash,
    required super.status,
  });

  factory TransferResultModel.fromJson(Map<String, dynamic> json) {
    return TransferResultModel(
      txHash: json['tx_hash'] as String,
      status: _parseStatus(json['status'] as String?),
    );
  }

  static TransferStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return TransferStatus.pending;
      case 'submitted':
        return TransferStatus.submitted;
      case 'confirmed':
        return TransferStatus.confirmed;
      case 'failed':
        return TransferStatus.failed;
      default:
        return TransferStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tx_hash': txHash,
      'status': status.name,
    };
  }
}

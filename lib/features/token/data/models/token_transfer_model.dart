import '../../domain/entities/token_transfer.dart';

class TokenTransferDataModel {
  final String to;
  final String from;
  final String data;
  final String value;
  final String gasLimit;
  final String maxFeePerGas;
  final String maxPriorityFeePerGas;
  final String nonce;
  final String network;

  const TokenTransferDataModel({
    required this.to,
    required this.from,
    required this.data,
    required this.value,
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.nonce,
    required this.network,
  });

  factory TokenTransferDataModel.fromJson(Map<String, dynamic> json) {
    return TokenTransferDataModel(
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

  TokenTransferData toEntity() {
    return TokenTransferData(
      to: to,
      from: from,
      data: data,
      value: value,
      gasLimit: gasLimit,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      nonce: nonce,
      network: network,
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

class TokenTransferResultModel {
  final String transactionHash;

  const TokenTransferResultModel({
    required this.transactionHash,
  });

  factory TokenTransferResultModel.fromJson(Map<String, dynamic> json) {
    return TokenTransferResultModel(
      transactionHash: json['tx_hash'] as String? ?? json['transactionHash'] as String? ?? '',
    );
  }

  TokenTransferResult toEntity() {
    return TokenTransferResult(transactionHash: transactionHash);
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionHash': transactionHash,
    };
  }
}

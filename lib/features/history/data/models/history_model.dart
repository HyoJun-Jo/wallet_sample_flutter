import '../../domain/entities/history_entry.dart';

class HistoryModel {
  final String hash;
  final String from;
  final String to;
  final String value;
  final String? tokenSymbol;
  final String? tokenName;
  final int? tokenDecimals;
  final String? contractAddress;
  final String? tokenId;
  final String network;
  final DateTime timestamp;
  final HistoryType type;
  final HistoryDirection direction;
  final String status;
  final String? gasUsed;
  final String? gasPrice;

  const HistoryModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    this.tokenSymbol,
    this.tokenName,
    this.tokenDecimals,
    this.contractAddress,
    this.tokenId,
    required this.network,
    required this.timestamp,
    required this.type,
    required this.direction,
    required this.status,
    this.gasUsed,
    this.gasPrice,
  });

  factory HistoryModel.fromJson(
    Map<String, dynamic> json,
    String walletAddress,
  ) {
    final extra = json['extra'] as Map<String, dynamic>?;

    String from = json['txAddress'] as String? ?? '';
    String to = json['rxAddress'] as String? ?? '';
    String value = (json['value']?.toString()) ?? '0';

    if (json['tokenSenderAddress'] != null) {
      from = json['tokenSenderAddress'] as String;
    }
    if (json['tokenReceiverAddress'] != null) {
      to = json['tokenReceiverAddress'] as String;
    }
    if (json['tokenValue'] != null) {
      value = json['tokenValue'].toString();
    }

    String? tokenSymbol = extra?['token_symbol'] as String?;
    String? tokenName = extra?['token_name'] as String?;
    int? tokenDecimals;

    final contract = extra?['contract'] as Map<String, dynamic>?;
    if (contract != null) {
      tokenSymbol ??= contract['symbol'] as String?;
      tokenName ??= contract['name'] as String?;
      if (contract['decimals'] != null) {
        final decimalsValue = contract['decimals'];
        if (decimalsValue is int) {
          tokenDecimals = decimalsValue;
        } else if (decimalsValue is String) {
          tokenDecimals = int.tryParse(decimalsValue);
        }
      }
    }

    if (tokenDecimals == null && extra?['token_decimals'] != null) {
      final decimalsValue = extra!['token_decimals'];
      if (decimalsValue is int) {
        tokenDecimals = decimalsValue;
      } else if (decimalsValue is String) {
        tokenDecimals = int.tryParse(decimalsValue);
      }
    }

    String? tokenId;
    if (json['nftId'] != null) {
      final nftId = json['nftId'];
      if (nftId is String) {
        tokenId = nftId;
      } else if (nftId is int) {
        tokenId = nftId.toString();
      } else if (nftId is double) {
        tokenId = BigInt.from(nftId).toString();
      } else {
        tokenId = nftId.toString();
      }
    }

    return HistoryModel(
      hash: json['txHash'] as String? ?? '',
      from: from,
      to: to,
      value: value,
      tokenSymbol: tokenSymbol,
      tokenName: tokenName,
      tokenDecimals: tokenDecimals,
      contractAddress: json['receiptContractAddress'] as String? ??
          extra?['asset_address'] as String?,
      tokenId: tokenId,
      network: json['network'] as String? ?? '',
      timestamp: _parseTimestamp(json['timeStamp']),
      type: HistoryType.fromRaw(json['transferType'] as String?),
      direction: _parseDirection(from, walletAddress, extra),
      status: (json['txReceiptStatus'] == true) ? 'confirmed' : 'failed',
      gasUsed: json['receiptGasUsed']?.toString(),
      gasPrice: json['gasPrice']?.toString(),
    );
  }

  factory HistoryModel.fromCacheJson(Map<String, dynamic> json) {
    return HistoryModel(
      hash: json['hash'] as String,
      from: json['from_address'] as String,
      to: json['to_address'] as String,
      value: json['value'] as String,
      tokenSymbol: json['token_symbol'] as String?,
      tokenName: json['token_name'] as String?,
      tokenDecimals: json['token_decimals'] as int?,
      contractAddress: json['contract_address'] as String?,
      tokenId: json['token_id'] as String?,
      network: json['network'] as String,
      timestamp: _parseTimestamp(json['block_timestamp']),
      type: HistoryType.fromRaw(json['transfer_type'] as String?),
      direction: _parseDirectionFromCache(json['direction'] as String?),
      status: json['status'] as String,
      gasUsed: json['gas_used'] as String?,
      gasPrice: json['gas_price'] as String?,
    );
  }

  HistoryEntry toEntity() {
    return HistoryEntry(
      hash: hash,
      from: from,
      to: to,
      value: value,
      tokenSymbol: tokenSymbol,
      tokenName: tokenName,
      tokenDecimals: tokenDecimals,
      contractAddress: contractAddress,
      tokenId: tokenId,
      network: network,
      timestamp: timestamp,
      type: type,
      direction: direction,
      status: status,
      gasUsed: gasUsed,
      gasPrice: gasPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'from_address': from,
      'to_address': to,
      'value': value,
      'token_symbol': tokenSymbol,
      'token_name': tokenName,
      'token_decimals': tokenDecimals,
      'contract_address': contractAddress,
      'token_id': tokenId,
      'network': network,
      'block_timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'transfer_type': type.raw,
      'direction': direction.name,
      'status': status,
      'gas_used': gasUsed,
      'gas_price': gasPrice,
    };
  }

  static HistoryDirection _parseDirection(
    String from,
    String walletAddress,
    Map<String, dynamic>? extra,
  ) {
    final extraDirection = extra?['direction'] as String?;
    if (extraDirection != null) {
      if (extraDirection.toUpperCase() == 'SEND') {
        return HistoryDirection.outgoing;
      } else if (extraDirection.toUpperCase() == 'RECEIVE') {
        return HistoryDirection.incoming;
      }
    }

    return from.toLowerCase() == walletAddress.toLowerCase()
        ? HistoryDirection.outgoing
        : HistoryDirection.incoming;
  }

  static HistoryDirection _parseDirectionFromCache(String? direction) {
    if (direction == 'outgoing') return HistoryDirection.outgoing;
    return HistoryDirection.incoming;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

import '../../domain/entities/transaction_history.dart';

/// Transaction history model for API response parsing
class TransactionHistoryModel extends TransactionHistory {
  const TransactionHistoryModel({
    required super.hash,
    required super.from,
    required super.to,
    required super.value,
    super.tokenSymbol,
    super.tokenName,
    super.tokenDecimals,
    super.contractAddress,
    super.tokenId,
    required super.network,
    required super.timestamp,
    required super.type,
    required super.direction,
    required super.status,
    super.gasUsed,
    super.gasPrice,
  });

  factory TransactionHistoryModel.fromJson(
    Map<String, dynamic> json,
    String walletAddress,
  ) {
    // Parse extra field for token details
    final extra = json['extra'] as Map<String, dynamic>?;

    // Determine from/to addresses
    // For token transfers, use tokenSenderAddress/tokenReceiverAddress
    // For coin transfers, use txAddress/rxAddress
    String from = json['txAddress'] as String? ?? '';
    String to = json['rxAddress'] as String? ?? '';
    String value = (json['value']?.toString()) ?? '0';

    // Token transfer specifics
    if (json['tokenSenderAddress'] != null) {
      from = json['tokenSenderAddress'] as String;
    }
    if (json['tokenReceiverAddress'] != null) {
      to = json['tokenReceiverAddress'] as String;
    }
    if (json['tokenValue'] != null) {
      value = json['tokenValue'].toString();
    }

    // Get token info from extra
    String? tokenSymbol = extra?['token_symbol'] as String?;
    String? tokenName = extra?['token_name'] as String?;
    int? tokenDecimals;

    // Check for Kaia contract field
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

    // Fallback to Ethereum extra decimals
    if (tokenDecimals == null && extra?['token_decimals'] != null) {
      final decimalsValue = extra!['token_decimals'];
      if (decimalsValue is int) {
        tokenDecimals = decimalsValue;
      } else if (decimalsValue is String) {
        tokenDecimals = int.tryParse(decimalsValue);
      }
    }

    // NFT token ID
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

    return TransactionHistoryModel(
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
      type: TransactionType.fromRaw(json['transferType'] as String?),
      direction: _parseDirection(from, walletAddress, extra),
      status: (json['txReceiptStatus'] == true) ? 'confirmed' : 'failed',
      gasUsed: json['receiptGasUsed']?.toString(),
      gasPrice: json['gasPrice']?.toString(),
    );
  }

  static TransactionDirection _parseDirection(
    String to,
    String walletAddress,
    Map<String, dynamic>? extra,
  ) {
    // Check extra.direction first (EthereumExtra - SEND/RECEIVE)
    final extraDirection = extra?['direction'] as String?;
    if (extraDirection != null) {
      if (extraDirection.toUpperCase() == 'SEND') {
        return TransactionDirection.outgoing;
      } else if (extraDirection.toUpperCase() == 'RECEIVE') {
        return TransactionDirection.incoming;
      }
    }

    // Direction: receiver == walletAddress → Receive, else → Send
    return to.toLowerCase() == walletAddress.toLowerCase()
        ? TransactionDirection.incoming
        : TransactionDirection.outgoing;
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

  /// Alias for toJson() for cache compatibility
  Map<String, dynamic> toCacheJson() => toJson();

  factory TransactionHistoryModel.fromEntity(TransactionHistory entity) {
    return TransactionHistoryModel(
      hash: entity.hash,
      from: entity.from,
      to: entity.to,
      value: entity.value,
      tokenSymbol: entity.tokenSymbol,
      tokenName: entity.tokenName,
      tokenDecimals: entity.tokenDecimals,
      contractAddress: entity.contractAddress,
      tokenId: entity.tokenId,
      network: entity.network,
      timestamp: entity.timestamp,
      type: entity.type,
      direction: entity.direction,
      status: entity.status,
      gasUsed: entity.gasUsed,
      gasPrice: entity.gasPrice,
    );
  }

  factory TransactionHistoryModel.fromCacheJson(Map<String, dynamic> json) {
    return TransactionHistoryModel(
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
      type: TransactionType.fromRaw(json['transfer_type'] as String?),
      direction: _parseDirectionFromCache(json['direction'] as String?),
      status: json['status'] as String,
      gasUsed: json['gas_used'] as String?,
      gasPrice: json['gas_price'] as String?,
    );
  }

  static TransactionDirection _parseDirectionFromCache(String? direction) {
    if (direction == 'outgoing') return TransactionDirection.outgoing;
    return TransactionDirection.incoming;
  }
}

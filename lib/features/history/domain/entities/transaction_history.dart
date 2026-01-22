import 'package:equatable/equatable.dart';

/// Transaction type based on API transfer_type field
enum TransactionType {
  coinTransfer('coin_transfer'),
  tokenTransfer('token_transfer'),
  nftTransfer('nft_transfer'),
  contractCall('contract_call');

  final String raw;
  const TransactionType(this.raw);

  static TransactionType fromRaw(String? raw) {
    if (raw == null) return TransactionType.contractCall;
    return TransactionType.values.firstWhere(
      (t) => t.raw == raw,
      orElse: () => TransactionType.contractCall,
    );
  }
}

/// Transaction direction
enum TransactionDirection {
  incoming,
  outgoing,
}

/// Transaction history entity
class TransactionHistory extends Equatable {
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
  final TransactionType type;
  final TransactionDirection direction;
  final String status;
  final String? gasUsed;
  final String? gasPrice;

  const TransactionHistory({
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

  /// Check if this is an incoming transaction
  bool get isIncoming => direction == TransactionDirection.incoming;

  /// Check if this is an outgoing transaction
  bool get isOutgoing => direction == TransactionDirection.outgoing;

  /// Check if this is a token transaction (for Token History)
  bool get isTokenTransaction => type != TransactionType.nftTransfer;

  /// Check if this is an NFT transaction (for NFT History)
  bool get isNftTransaction => type == TransactionType.nftTransfer;

  @override
  List<Object?> get props => [
        hash,
        from,
        to,
        value,
        tokenSymbol,
        tokenName,
        tokenDecimals,
        contractAddress,
        tokenId,
        network,
        timestamp,
        type,
        direction,
        status,
        gasUsed,
        gasPrice,
      ];
}

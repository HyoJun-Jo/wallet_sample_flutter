import 'package:equatable/equatable.dart';

enum HistoryType {
  coinTransfer('coin_transfer'),
  tokenTransfer('token_transfer'),
  nftTransfer('nft_transfer'),
  contractCall('contract_call');

  final String raw;
  const HistoryType(this.raw);

  static HistoryType fromRaw(String? raw) {
    if (raw == null) return HistoryType.contractCall;
    return HistoryType.values.firstWhere(
      (t) => t.raw == raw,
      orElse: () => HistoryType.contractCall,
    );
  }
}

enum HistoryDirection {
  incoming,
  outgoing,
}

class HistoryEntry extends Equatable {
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

  const HistoryEntry({
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

  bool get isIncoming => direction == HistoryDirection.incoming;

  bool get isOutgoing => direction == HistoryDirection.outgoing;

  bool get isToken => type != HistoryType.nftTransfer;

  bool get isNft => type == HistoryType.nftTransfer;

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

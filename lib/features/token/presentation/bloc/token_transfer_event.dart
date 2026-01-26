import 'package:equatable/equatable.dart';

import '../../domain/entities/token_transfer.dart';

/// Token transfer event base class
abstract class TokenTransferEvent extends Equatable {
  const TokenTransferEvent();

  @override
  List<Object?> get props => [];
}

/// Prepare transfer data (for confirmation UI)
class PrepareTokenTransfer extends TokenTransferEvent {
  final String fromAddress;
  final String toAddress;
  final String amount;
  final String contractAddress; // Empty for native token
  final String network;

  const PrepareTokenTransfer({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.contractAddress,
    required this.network,
  });

  @override
  List<Object?> get props => [fromAddress, toAddress, amount, contractAddress, network];
}

/// Execute transfer (entire flow: sign + send)
class TokenTransferRequested extends TokenTransferEvent {
  final TokenTransferParams params;

  const TokenTransferRequested({required this.params});

  @override
  List<Object?> get props => [params];
}

/// Reset transfer state
class TokenTransferReset extends TokenTransferEvent {
  const TokenTransferReset();
}

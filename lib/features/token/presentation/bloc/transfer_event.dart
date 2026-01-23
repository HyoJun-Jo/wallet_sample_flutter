import 'package:equatable/equatable.dart';

import '../../domain/entities/transfer.dart';

/// Transfer event base class
abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

/// Prepare transfer data (for confirmation UI)
class PrepareTransfer extends TransferEvent {
  final String fromAddress;
  final String toAddress;
  final String amount;
  final String contractAddress; // Empty for native token
  final String network;

  const PrepareTransfer({
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
class TransferRequested extends TransferEvent {
  final TransferParams params;

  const TransferRequested({required this.params});

  @override
  List<Object?> get props => [params];
}

/// Reset transfer state
class TransferReset extends TransferEvent {
  const TransferReset();
}

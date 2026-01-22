import 'package:equatable/equatable.dart';

/// Transfer event base class
abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

/// Request to create transfer data
class TransferDataRequested extends TransferEvent {
  final String fromAddress;
  final String toAddress;
  final String amount;
  final String contractAddress;
  final String network;

  const TransferDataRequested({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.contractAddress,
    required this.network,
  });

  @override
  List<Object?> get props => [
        fromAddress,
        toAddress,
        amount,
        contractAddress,
        network,
      ];
}

/// Send raw transaction
class SendTransactionRequested extends TransferEvent {
  final String network;
  final String rawData;

  const SendTransactionRequested({
    required this.network,
    required this.rawData,
  });

  @override
  List<Object?> get props => [network, rawData];
}

/// Cancel transfer
class TransferCancelled extends TransferEvent {
  const TransferCancelled();
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/sign_request.dart';

/// Signing event base class
abstract class SigningEvent extends Equatable {
  const SigningEvent();

  @override
  List<Object?> get props => [];
}

/// Sign message request
class SignMessageRequested extends SigningEvent {
  final MessageType msgType;
  final String accountId;
  final String network;
  final String msg;
  final String language;

  const SignMessageRequested({
    required this.msgType,
    required this.accountId,
    required this.network,
    required this.msg,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [msgType, accountId, network, msg, language];
}

/// Sign typed data request (EIP-712)
class SignTypedDataRequested extends SigningEvent {
  final String accountId;
  final String network;
  final String typeDataMsg;

  const SignTypedDataRequested({
    required this.accountId,
    required this.network,
    required this.typeDataMsg,
  });

  @override
  List<Object?> get props => [accountId, network, typeDataMsg];
}

/// Sign hash request
class SignHashRequested extends SigningEvent {
  final String accountId;
  final String network;
  final String hash;

  const SignHashRequested({
    required this.accountId,
    required this.network,
    required this.hash,
  });

  @override
  List<Object?> get props => [accountId, network, hash];
}

/// Cancel signing
class SigningCancelled extends SigningEvent {
  const SigningCancelled();
}

/// Sign EIP-1559 transaction request
class SignEip1559Requested extends SigningEvent {
  final String accountId;
  final String network;
  final String from;
  final String to;
  final String value;
  final String data;
  final String nonce;
  final String gasLimit;
  final String maxFeePerGas;
  final String maxPriorityFeePerGas;

  const SignEip1559Requested({
    required this.accountId,
    required this.network,
    required this.from,
    required this.to,
    required this.value,
    required this.data,
    required this.nonce,
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
  });

  @override
  List<Object?> get props => [
        accountId,
        network,
        from,
        to,
        value,
        data,
        nonce,
        gasLimit,
        maxFeePerGas,
        maxPriorityFeePerGas,
      ];
}

/// Send signed transaction request
class SendTransactionRequested extends SigningEvent {
  final String network;
  final String signedTx;

  const SendTransactionRequested({
    required this.network,
    required this.signedTx,
  });

  @override
  List<Object?> get props => [network, signedTx];
}

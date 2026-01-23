import 'package:equatable/equatable.dart';

/// Message type for signing
enum MessageType {
  transaction,
  message,
  typedData,
  hash,
}

/// Personal sign params (personal_sign)
class PersonalSignParams extends Equatable {
  final MessageType msgType;
  final String accountId;
  final String network;
  final String message;
  final String language;

  const PersonalSignParams({
    required this.msgType,
    required this.accountId,
    required this.network,
    required this.message,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [msgType, accountId, network, message, language];
}

/// Sign typed data params (EIP-712)
class SignTypedDataParams extends Equatable {
  final String accountId;
  final String network;
  final String messageJson;

  const SignTypedDataParams({
    required this.accountId,
    required this.network,
    required this.messageJson,
  });

  @override
  List<Object?> get props => [accountId, network, messageJson];
}

/// Sign hash params
class SignHashParams extends Equatable {
  final String accountId;
  final String network;
  final String hash;

  const SignHashParams({
    required this.accountId,
    required this.network,
    required this.hash,
  });

  @override
  List<Object?> get props => [accountId, network, hash];
}

/// Sign result
class SignResult extends Equatable {
  final String signature;
  final String? txHash;
  final String? serializedTx;
  final String? rawTx;

  const SignResult({
    required this.signature,
    this.txHash,
    this.serializedTx,
    this.rawTx,
  });

  @override
  List<Object?> get props => [signature, txHash, serializedTx, rawTx];
}

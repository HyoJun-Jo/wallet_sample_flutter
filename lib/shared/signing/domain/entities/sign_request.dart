import 'package:equatable/equatable.dart';

/// Message type for signing
enum MessageType {
  transaction,
  message,
  typedData,
  hash,
}

/// Sign request entity
class SignRequest extends Equatable {
  final MessageType msgType;
  final String accountId;
  final String network;
  final String msg;
  final String language;

  const SignRequest({
    required this.msgType,
    required this.accountId,
    required this.network,
    required this.msg,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [msgType, accountId, network, msg, language];
}

/// Typed data sign request
class TypedDataSignRequest extends Equatable {
  final String accountId;
  final String network;
  final String typeDataMsg;

  const TypedDataSignRequest({
    required this.accountId,
    required this.network,
    required this.typeDataMsg,
  });

  @override
  List<Object?> get props => [accountId, network, typeDataMsg];
}

/// Hash sign request
class HashSignRequest extends Equatable {
  final String accountId;
  final String network;
  final String hash;

  const HashSignRequest({
    required this.accountId,
    required this.network,
    required this.hash,
  });

  @override
  List<Object?> get props => [accountId, network, hash];
}

/// Pre-sign result
class PreSignResult extends Equatable {
  final String signId;
  final String hashToSign;
  final String mpcPublicKey;

  const PreSignResult({
    required this.signId,
    required this.hashToSign,
    required this.mpcPublicKey,
  });

  @override
  List<Object?> get props => [signId, hashToSign, mpcPublicKey];
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

/// EIP-1559 Transaction Sign Request
class Eip1559SignRequest extends Equatable {
  final String accountId;
  final String network;
  final String from;
  final String to;
  final String value;
  final String data;
  final String nonce;
  final String gasLimit;
  final String maxPriorityFeePerGas;
  final String maxFeePerGas;

  const Eip1559SignRequest({
    required this.accountId,
    required this.network,
    required this.from,
    required this.to,
    required this.value,
    required this.data,
    required this.nonce,
    required this.gasLimit,
    required this.maxPriorityFeePerGas,
    required this.maxFeePerGas,
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
        maxPriorityFeePerGas,
        maxFeePerGas,
      ];
}

/// Gas Fee Info
class GasFeeInfo extends Equatable {
  final String gasPrice;
  final String? maxFeePerGas;
  final String? maxPriorityFeePerGas;
  final String estimatedGas;

  const GasFeeInfo({
    required this.gasPrice,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    required this.estimatedGas,
  });

  @override
  List<Object?> get props =>
      [gasPrice, maxFeePerGas, maxPriorityFeePerGas, estimatedGas];
}

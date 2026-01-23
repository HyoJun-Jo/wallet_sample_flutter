import 'package:equatable/equatable.dart';

/// Sign type for transaction signing
enum SignType { legacy, eip1559, personal }

/// Personal sign params (personal_sign)
class PersonalSignParams extends Equatable {
  final String network;
  final String message;

  const PersonalSignParams({
    required this.network,
    required this.message,
  });

  @override
  List<Object?> get props => [network, message];
}

/// Personal sign result
class PersonalSignResult extends Equatable {
  final String serializedTx;
  final String rawTx;

  const PersonalSignResult({
    required this.serializedTx,
    required this.rawTx,
  });

  @override
  List<Object?> get props => [serializedTx, rawTx];
}

/// Sign typed data params (EIP-712)
class SignTypedDataParams extends Equatable {
  final String network;
  final String messageJson;
  final String version;

  const SignTypedDataParams({
    required this.network,
    required this.messageJson,
    this.version = 'v4',
  });

  @override
  List<Object?> get props => [network, messageJson, version];
}

/// Sign typed data result
class SignTypedDataResult extends Equatable {
  final String serializedTx;
  final String rawTx;

  const SignTypedDataResult({
    required this.serializedTx,
    required this.rawTx,
  });

  @override
  List<Object?> get props => [serializedTx, rawTx];
}

/// Sign hash params
class SignHashParams extends Equatable {
  final String network;
  final String hash;

  const SignHashParams({
    required this.network,
    required this.hash,
  });

  @override
  List<Object?> get props => [network, hash];
}

/// Sign hash result
class SignHashResult extends Equatable {
  final String serializedTx;
  final String rawTx;

  const SignHashResult({
    required this.serializedTx,
    required this.rawTx,
  });

  @override
  List<Object?> get props => [serializedTx, rawTx];
}

/// Sign transaction params (EIP-1559)
class SignTransactionParams extends Equatable {
  final String network;
  final String from;
  final String to;
  final String value;
  final String data;
  final String nonce;
  final String gasLimit;
  final String maxPriorityFeePerGas;
  final String maxFeePerGas;
  final SignType type;

  const SignTransactionParams({
    required this.network,
    required this.from,
    required this.to,
    required this.value,
    required this.data,
    required this.nonce,
    required this.gasLimit,
    required this.maxPriorityFeePerGas,
    required this.maxFeePerGas,
    this.type = SignType.eip1559,
  });

  @override
  List<Object?> get props => [
        network,
        from,
        to,
        value,
        data,
        nonce,
        gasLimit,
        maxPriorityFeePerGas,
        maxFeePerGas,
        type,
      ];
}

/// Signed transaction result
class SignedTransaction extends Equatable {
  final String serializedTx;
  final String rawTx;

  const SignedTransaction({
    required this.serializedTx,
    required this.rawTx,
  });

  @override
  List<Object?> get props => [serializedTx, rawTx];
}

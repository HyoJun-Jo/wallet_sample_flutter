import '../../domain/entities/signing_entities.dart';

/// API 응답 DTO (모든 서명 API가 동일한 구조 반환)
class SignResponseModel {
  final String serializedTx;
  final String rawTx;

  const SignResponseModel({
    required this.serializedTx,
    required this.rawTx,
  });

  factory SignResponseModel.fromJson(Map<String, dynamic> json) {
    return SignResponseModel(
      serializedTx: json['serializedTx']?.toString() ?? '',
      rawTx: json['rawTx']?.toString() ?? '',
    );
  }

  PersonalSignResult toPersonalSignResult() {
    return PersonalSignResult(
      serializedTx: serializedTx,
      rawTx: rawTx,
    );
  }

  SignTypedDataResult toSignTypedDataResult() {
    return SignTypedDataResult(
      serializedTx: serializedTx,
      rawTx: rawTx,
    );
  }

  SignedTransaction toSignedTransaction() {
    return SignedTransaction(
      serializedTx: serializedTx,
      rawTx: rawTx,
    );
  }

  SignHashResult toSignHashResult() {
    return SignHashResult(
      serializedTx: serializedTx,
      rawTx: rawTx,
    );
  }
}

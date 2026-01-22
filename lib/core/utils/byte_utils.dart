import 'dart:typed_data';

/// Byte manipulation utilities for cryptographic operations
class ByteUtils {
  ByteUtils._();

  /// Convert BigInt to fixed-length byte array (big-endian)
  static Uint8List bigIntToBytes(BigInt number, int length) {
    final bytes = Uint8List(length);
    var temp = number;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (temp & BigInt.from(0xff)).toInt();
      temp = temp >> 8;
    }
    return bytes;
  }

  /// Convert byte array to BigInt (big-endian)
  static BigInt bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Convert bytes to hex string (without 0x prefix)
  static String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Convert hex string to bytes
  static Uint8List hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (cleanHex.length % 2 != 0) {
      throw ArgumentError('Hex string must have even length');
    }
    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  /// Concatenate multiple byte arrays
  static Uint8List concat(List<Uint8List> arrays) {
    final totalLength = arrays.fold<int>(0, (sum, arr) => sum + arr.length);
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final arr in arrays) {
      result.setRange(offset, offset + arr.length, arr);
      offset += arr.length;
    }
    return result;
  }

  /// Extract a sublist from bytes
  static Uint8List slice(Uint8List bytes, int start, [int? end]) {
    return Uint8List.fromList(bytes.sublist(start, end));
  }

  /// Pad bytes to specified length (left padding with zeros)
  static Uint8List padLeft(Uint8List bytes, int length) {
    if (bytes.length >= length) return bytes;
    final padded = Uint8List(length);
    padded.setRange(length - bytes.length, length, bytes);
    return padded;
  }

  /// Compare two byte arrays for equality
  static bool equals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// XOR two byte arrays
  static Uint8List xor(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      throw ArgumentError('Byte arrays must have same length');
    }
    final result = Uint8List(a.length);
    for (var i = 0; i < a.length; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }
}

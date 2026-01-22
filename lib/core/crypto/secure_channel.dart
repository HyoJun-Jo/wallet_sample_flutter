import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../utils/byte_utils.dart';

/// Secure Channel data class
class SecureChannelData {
  final String channelId;
  final Uint8List sharedSecret;
  final DateTime createdAt;

  SecureChannelData({
    required this.channelId,
    required this.sharedSecret,
    required this.createdAt,
  });

  /// Check if the channel has expired
  bool isExpired({int expireMinutes = 20}) {
    final expireTime = createdAt.add(Duration(minutes: expireMinutes));
    return DateTime.now().isAfter(expireTime);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'sharedSecret': base64Encode(sharedSecret),
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create from JSON
  factory SecureChannelData.fromJson(Map<String, dynamic> json) {
    return SecureChannelData(
      channelId: json['channelId'] as String,
      sharedSecret: base64Decode(json['sharedSecret'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Secure Channel utility for ECDH key exchange and AES encryption
class SecureChannel {
  SecureChannel._();
  static final SecureChannel instance = SecureChannel._();

  final _secureRandom = FortunaRandom();
  bool _isInitialized = false;

  /// Initialize the secure random generator
  void _initSecureRandom() {
    if (_isInitialized) return;

    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    _secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    _isInitialized = true;
  }

  /// Generate an EC key pair using secp256r1 (P-256) curve
  AsymmetricKeyPair<PublicKey, PrivateKey> generateKeyPair() {
    _initSecureRandom();

    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, _secureRandom));

    return generator.generateKeyPair();
  }

  /// Serialize public key to uncompressed format (0x04 || x || y)
  /// Returns hex string without 0x prefix
  String serializeUncompressedPublicKey(ECPublicKey publicKey) {
    final point = publicKey.Q!;
    final xBytes = ByteUtils.bigIntToBytes(point.x!.toBigInteger()!, 32);
    final yBytes = ByteUtils.bigIntToBytes(point.y!.toBigInteger()!, 32);

    final uncompressed = Uint8List(65);
    uncompressed[0] = 0x04;
    uncompressed.setRange(1, 33, xBytes);
    uncompressed.setRange(33, 65, yBytes);

    return ByteUtils.bytesToHex(uncompressed);
  }

  /// Create public key from uncompressed hex string
  /// Format: 04 + 32 bytes X + 32 bytes Y
  ECPublicKey createPublicKeyFromUncompressed(String uncompressed) {
    // Remove '0x' prefix if present
    final hexString = uncompressed.startsWith('0x')
        ? uncompressed.substring(2)
        : uncompressed;

    final bytes = ByteUtils.hexToBytes(hexString);
    if (bytes.length != 65 || bytes[0] != 0x04) {
      throw ArgumentError('Invalid uncompressed public key format');
    }

    // Extract X and Y coordinates (skip first byte which is 0x04)
    final xBytes = bytes.sublist(1, 33);
    final yBytes = bytes.sublist(33, 65);

    final x = ByteUtils.bytesToBigInt(xBytes);
    final y = ByteUtils.bytesToBigInt(yBytes);

    final curve = ECCurve_secp256r1();
    final point = curve.curve.createPoint(x, y);

    return ECPublicKey(point, curve);
  }

  /// Compute ECDH shared secret via manual point multiplication
  Uint8List computeSharedSecret(ECPublicKey publicKey, ECPrivateKey privateKey) {
    // Multiply server's public key point by our private key
    final sharedPoint = publicKey.Q! * privateKey.d;

    if (sharedPoint == null || sharedPoint.isInfinity) {
      throw ArgumentError('Invalid shared point');
    }

    // X coordinate of shared point is the shared secret
    final xCoord = sharedPoint.x!.toBigInteger()!;
    return ByteUtils.bigIntToBytes(xCoord, 32);
  }

  /// Encrypt plaintext using AES-CBC with PKCS7 padding
  /// Key: first 16 bytes of shared secret
  /// IV: bytes 16-32 of shared secret
  String encrypt(String plaintext, Uint8List sharedSecret) {
    final key = Uint8List.fromList(sharedSecret.sublist(0, 16));
    final iv = Uint8List.fromList(sharedSecret.sublist(16, 32));

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );
    cipher.init(true, params);

    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encryptedBytes = cipher.process(plainBytes);

    return base64Encode(encryptedBytes);
  }

  /// Decrypt ciphertext using AES-CBC with PKCS7 padding
  String decrypt(Uint8List encrypted, Uint8List sharedSecret) {
    final key = Uint8List.fromList(sharedSecret.sublist(0, 16));
    final iv = Uint8List.fromList(sharedSecret.sublist(16, 32));

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );
    cipher.init(false, params);

    final decrypted = cipher.process(encrypted);
    return utf8.decode(decrypted);
  }

  /// Decrypt base64-encoded ciphertext
  String decryptBase64(String encryptedBase64, Uint8List sharedSecret) {
    final encrypted = base64Decode(encryptedBase64);
    return decrypt(encrypted, sharedSecret);
  }

  /// Generate a random string of specified length
  String generateRandomString(int length) {
    _initSecureRandom();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (_) => chars[_secureRandom.nextUint32() % chars.length],
    ).join();
  }
}

import 'dart:developer';

/// Utility class for Ethereum unit conversions
/// Aligned with SDK: wallet-sdk-react/src/core/utils/conversion.ts
class WeiUtils {
  WeiUtils._();

  /// Parse hex string to BigInt
  static BigInt parseHex(String hex) {
    if (hex.isEmpty) return BigInt.zero;
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    return BigInt.tryParse(cleanHex, radix: 16) ?? BigInt.zero;
  }

  /// Convert Wei BigInt to decimal string with given decimals
  /// SDK equivalent: fromWei(weiHex, decimals)
  static String fromWei(BigInt wei, int decimals) {
    if (wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(decimals);
    final intPart = wei ~/ divisor;
    final decPart = wei % divisor;

    if (decPart == BigInt.zero) {
      return intPart.toString();
    }

    final decStr = decPart.toString().padLeft(decimals, '0');
    final trimmed = decStr.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) {
      return intPart.toString();
    }
    return '$intPart.$trimmed';
  }

  /// Convert Wei hex string to decimal string
  static String fromWeiHex(String weiHex, int decimals) {
    return fromWei(parseHex(weiHex), decimals);
  }

  /// Convert Wei BigInt to Gwei string
  /// SDK equivalent: weiHexToGwei(weiHex)
  static String toGwei(BigInt wei) {
    final gwei = wei ~/ BigInt.from(10).pow(9);
    final remainder = wei % BigInt.from(10).pow(9);
    if (remainder == BigInt.zero) {
      return gwei.toString();
    }
    final decStr = remainder.toString().padLeft(9, '0');
    final trimmed = decStr.replaceAll(RegExp(r'0+$'), '');
    return '$gwei${trimmed.isNotEmpty ? '.$trimmed' : ''}';
  }

  /// Convert Wei hex string to Gwei string
  static String weiHexToGwei(String weiHex) {
    return toGwei(parseHex(weiHex));
  }

  /// Convert amount string to Wei hex
  /// SDK equivalent: toWeiHex(amount, decimals)
  static String toWeiHex(String amount, int decimals) {
    if (amount.isEmpty || amount == '0') return '0x0';

    try {
      final parts = amount.split('.');
      final integer = parts[0];
      final fraction = parts.length > 1 ? parts[1] : '';
      final paddedFraction = fraction.padRight(decimals, '0').substring(
          0, decimals > fraction.length ? decimals : fraction.length);
      final weiString = integer + paddedFraction.substring(0, decimals);
      final wei = BigInt.parse(weiString);
      return '0x${wei.toRadixString(16)}';
    } catch (e) {
      log('Failed to convert to wei: $amount, error: $e', name: 'WeiUtils');
      return '0x0';
    }
  }

  /// Convert Gwei string to Wei hex string
  /// SDK equivalent: gweiToWeiHex(gwei)
  static String gweiToWeiHex(String gwei) {
    if (gwei.startsWith('0x')) {
      return gwei;
    }

    try {
      final parts = gwei.split('.');
      final integer = parts[0];
      final decimal = parts.length > 1 ? parts[1] : '';
      final paddedDecimal = decimal.padRight(9, '0').substring(0, 9);
      final weiString = integer + paddedDecimal;
      return '0x${BigInt.parse(weiString).toRadixString(16)}';
    } catch (e) {
      log('Failed to convert gwei to wei: $gwei, error: $e', name: 'WeiUtils');
      return '0x3b9aca00'; // Default 1 Gwei
    }
  }

  /// Parse various value formats to Wei hex
  static String parseToWeiHex(String value) {
    if (value.isEmpty || value == '0') {
      return '0x0';
    }

    if (value.startsWith('0x')) {
      return value;
    }

    if (value.contains('.')) {
      // Decimal - assume ETH (18 decimals)
      return toWeiHex(value, 18);
    }

    // Decimal wei string - convert to hex
    try {
      final weiAmount = BigInt.parse(value);
      return '0x${weiAmount.toRadixString(16)}';
    } catch (e) {
      log('Failed to parse value to wei hex: $value, error: $e',
          name: 'WeiUtils');
      return '0x0';
    }
  }
}

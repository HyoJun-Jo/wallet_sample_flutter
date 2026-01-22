import 'dart:developer';

/// Utility class for Ethereum unit conversions
class WeiUtils {
  WeiUtils._();

  /// Convert Gwei to Wei hex string
  static String gweiToWeiHex(String gwei) {
    if (gwei.startsWith('0x')) {
      return gwei;
    }

    try {
      final value = double.tryParse(gwei) ?? 0;
      final wei = BigInt.from(value * 1e9);
      return '0x${wei.toRadixString(16)}';
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
      // Decimal - assume ETH
      try {
        final ethValue = double.tryParse(value) ?? 0;
        final wei = BigInt.from(ethValue * 1e18);
        return '0x${wei.toRadixString(16)}';
      } catch (e) {
        log('Failed to convert eth to wei: $value, error: $e', name: 'WeiUtils');
        return '0x0';
      }
    }

    // Decimal wei string - convert to hex
    try {
      final weiAmount = BigInt.parse(value);
      return '0x${weiAmount.toRadixString(16)}';
    } catch (e) {
      log('Failed to parse value to wei hex: $value, error: $e', name: 'WeiUtils');
      return '0x0';
    }
  }
}

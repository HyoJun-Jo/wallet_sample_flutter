import 'dart:developer';

/// Utility class for Ethereum unit conversions
/// Wei is the smallest unit (1 ETH = 10^18 Wei)
/// Gwei is commonly used for gas prices (1 Gwei = 10^9 Wei)
class WeiUtils {
  WeiUtils._();

  /// Convert Gwei to Wei hex string
  /// Handles both integer ("1") and decimal ("1.05242418") Gwei values
  /// Returns hex string with 0x prefix
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

  /// Convert ETH to Wei hex string
  /// Handles decimal ETH values like "0.01"
  static String ethToWeiHex(String eth) {
    if (eth.startsWith('0x')) {
      return eth;
    }

    try {
      final value = double.tryParse(eth) ?? 0;
      final wei = BigInt.from(value * 1e18);
      return '0x${wei.toRadixString(16)}';
    } catch (e) {
      log('Failed to convert eth to wei: $eth, error: $e', name: 'WeiUtils');
      return '0x0';
    }
  }

  /// Convert Wei to ETH as double
  static double weiToEth(String wei) {
    try {
      BigInt weiValue;
      if (wei.startsWith('0x')) {
        weiValue = BigInt.parse(wei.substring(2), radix: 16);
      } else {
        weiValue = BigInt.parse(wei);
      }
      return weiValue / BigInt.from(10).pow(18);
    } catch (e) {
      log('Failed to convert wei to eth: $wei, error: $e', name: 'WeiUtils');
      return 0.0;
    }
  }

  /// Convert Wei to Gwei as double
  static double weiToGwei(String wei) {
    try {
      BigInt weiValue;
      if (wei.startsWith('0x')) {
        weiValue = BigInt.parse(wei.substring(2), radix: 16);
      } else {
        weiValue = BigInt.parse(wei);
      }
      return weiValue / BigInt.from(10).pow(9);
    } catch (e) {
      log('Failed to convert wei to gwei: $wei, error: $e', name: 'WeiUtils');
      return 0.0;
    }
  }

  /// Parse various value formats to Wei hex
  /// Handles: hex (0x...), decimal wei string, ETH amount (with decimal)
  static String parseToWeiHex(String value) {
    if (value.isEmpty || value == '0') {
      return '0x0';
    }

    if (value.startsWith('0x')) {
      return value;
    }

    if (value.contains('.')) {
      // Decimal - assume ETH
      return ethToWeiHex(value);
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

  /// Convert decimal wei string to hex
  static String decimalToHex(String decimal) {
    if (decimal.startsWith('0x')) {
      return decimal;
    }

    try {
      final value = BigInt.parse(decimal);
      return '0x${value.toRadixString(16)}';
    } catch (e) {
      log('Failed to convert decimal to hex: $decimal, error: $e', name: 'WeiUtils');
      return '0x0';
    }
  }
}

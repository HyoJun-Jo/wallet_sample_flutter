/// Utility class for number and price formatting
class FormatUtils {
  FormatUtils._();

  /// Format large numbers with K/M suffix
  static String formatLargeNumber(double value, {int decimals = 2}) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(decimals)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(decimals)}K';
    }
    return value.toStringAsFixed(decimals);
  }

  /// Format token balance with smart decimal handling
  static String formatBalance(double balance, {int maxDecimals = 4}) {
    if (balance == 0) return '0';
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M';
    }
    if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K';
    }
    if (balance < 0.0001) {
      return '<0.0001';
    }
    return balance
        .toStringAsFixed(maxDecimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Format USD value with dollar sign
  static String formatUsd(double? value) {
    if (value == null) return '-';
    if (value < 0.01) return '<\$0.01';
    return '\$${_addCommas(value.toStringAsFixed(2))}';
  }

  /// Format total USD value with K/M suffix
  static String formatTotalUsd(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  /// Format KRW value with won sign
  static String formatKrw(double? value) {
    if (value == null) return '-';
    if (value < 1) return '<₩1';
    return '₩${_addCommas(value.toStringAsFixed(0))}';
  }

  /// Format percentage
  static String formatPercent(double value, {int decimals = 2}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  static String _addCommas(String value) {
    return value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

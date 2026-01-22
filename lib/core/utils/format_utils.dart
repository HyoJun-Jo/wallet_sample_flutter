/// Utility class for number and price formatting
class FormatUtils {
  FormatUtils._();

  /// Format large numbers with K/M suffix
  /// e.g., 1234567 → "1.23M", 1234 → "1.23K"
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
  /// e.g., 0.00001234 → "<0.0001", 1.23400000 → "1.234"
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

  /// Format USD value with dollar sign and comma separators
  /// e.g., 1234.56 → "$1,234.56", 0.001 → "<$0.01"
  static String formatUsd(double? value) {
    if (value == null) return '-';
    if (value < 0.01) return '<\$0.01';
    return '\$${_addCommas(value.toStringAsFixed(2))}';
  }

  /// Format total USD value with K/M suffix
  /// e.g., 1234567.89 → "$1.23M", 1234.56 → "$1.23K"
  static String formatTotalUsd(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  /// Format KRW value with won sign and comma separators
  /// e.g., 1234567 → "₩1,234,567"
  static String formatKrw(double? value) {
    if (value == null) return '-';
    if (value < 1) return '<₩1';
    return '₩${_addCommas(value.toStringAsFixed(0))}';
  }

  /// Format percentage
  /// e.g., 0.1234 → "12.34%"
  static String formatPercent(double value, {int decimals = 2}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Add comma separators to number string
  static String _addCommas(String value) {
    return value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

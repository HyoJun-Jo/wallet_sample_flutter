/// Utility class for blockchain address operations
class AddressUtils {
  AddressUtils._();

  /// Shorten address for display
  /// e.g., "0x1234...5678abcdef" → "0x1234...cdef"
  static String shorten(String address, {int prefixLength = 6, int suffixLength = 4}) {
    if (address.length <= prefixLength + suffixLength + 3) return address;
    return '${address.substring(0, prefixLength)}...${address.substring(address.length - suffixLength)}';
  }

  /// Validate EVM address format
  static bool isValidEvmAddress(String address) {
    if (!address.startsWith('0x')) return false;
    if (address.length != 42) return false;
    return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
  }

  /// Validate Solana address format
  static bool isValidSolanaAddress(String address) {
    if (address.length < 32 || address.length > 44) return false;
    return RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(address);
  }

  /// Check if address is zero address
  static bool isZeroAddress(String address) {
    return address == '0x0000000000000000000000000000000000000000';
  }

  /// Normalize address to checksum format (lowercase for comparison)
  static String normalize(String address) {
    return address.toLowerCase();
  }

  /// Compare two addresses (case-insensitive)
  static bool isSameAddress(String address1, String address2) {
    return normalize(address1) == normalize(address2);
  }
}

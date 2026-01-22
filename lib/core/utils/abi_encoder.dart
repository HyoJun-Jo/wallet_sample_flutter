/// ABI Encoder utility for encoding smart contract function calls
class AbiEncoder {
  AbiEncoder._();

  /// Encode ERC721 safeTransferFrom(address from, address to, uint256 tokenId)
  /// Function selector: 0x42842e0e
  static String encodeErc721SafeTransferFrom({
    required String from,
    required String to,
    required String tokenId,
  }) {
    const selector = '42842e0e';
    final fromPadded = _padAddress(from);
    final toPadded = _padAddress(to);
    final tokenIdPadded = _padUint256(tokenId);
    return '0x$selector$fromPadded$toPadded$tokenIdPadded';
  }

  /// Encode ERC1155 safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)
  /// Function selector: 0xf242432a
  static String encodeErc1155SafeTransferFrom({
    required String from,
    required String to,
    required String tokenId,
    required String amount,
  }) {
    const selector = 'f242432a';
    final fromPadded = _padAddress(from);
    final toPadded = _padAddress(to);
    final idPadded = _padUint256(tokenId);
    final amountPadded = _padUint256(amount);
    // Dynamic bytes data parameter: offset (0xa0 = 160 = 5 * 32 bytes) and length (0)
    const dataOffset = '00000000000000000000000000000000000000000000000000000000000000a0';
    const dataLength = '0000000000000000000000000000000000000000000000000000000000000000';
    return '0x$selector$fromPadded$toPadded$idPadded$amountPadded$dataOffset$dataLength';
  }

  /// Pad an Ethereum address to 32 bytes (left-padded with zeros)
  static String _padAddress(String addr) {
    final cleanAddr = addr.toLowerCase().replaceFirst('0x', '');
    return cleanAddr.padLeft(64, '0');
  }

  /// Pad a uint256 value to 32 bytes (left-padded with zeros)
  static String _padUint256(String value) {
    final bigInt = BigInt.parse(value);
    return bigInt.toRadixString(16).padLeft(64, '0');
  }
}

import 'package:flutter/material.dart';

import '../../../../core/enums/abc_network.dart';

/// Transaction Request Sheet
///
/// Shows dApp transaction request with transaction details
/// Reference: talken-mfe-flutter TransactionRequestSheet
class TransactionRequestSheet extends StatelessWidget {
  final String dappName;
  final AbcNetwork network;
  final String from;
  final String to;
  final String value;
  final String? data;
  final String? gasLimit;
  final VoidCallback onCancel;
  final VoidCallback onApprove;

  const TransactionRequestSheet({
    super.key,
    required this.dappName,
    required this.network,
    required this.from,
    required this.to,
    required this.value,
    this.data,
    this.gasLimit,
    required this.onCancel,
    required this.onApprove,
  });

  /// Format value from wei to readable format
  String _formatValue() {
    try {
      final valueHex = value.startsWith('0x') ? value.substring(2) : value;
      if (valueHex.isEmpty || valueHex == '0') return '0';

      final valueInt = BigInt.tryParse(valueHex, radix: 16);
      if (valueInt == null || valueInt == BigInt.zero) return '0';

      // Convert wei to ETH (18 decimals)
      final ethValue = valueInt / BigInt.from(10).pow(18);
      return ethValue.toStringAsFixed(6);
    } catch (_) {
      return value;
    }
  }

  /// Format address to short form
  String _formatAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatValue();
    final hasData = data != null && data!.isNotEmpty && data != '0x';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Subtitle
                    const Center(
                      child: Text(
                        'Transaction Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // dApp info
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.language,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                dappName,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Network section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              network.displayName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Transaction details section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Details',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // From
                          _buildDetailRow('From', _formatAddress(from)),
                          const SizedBox(height: 12),

                          // To
                          _buildDetailRow('To', _formatAddress(to)),
                          const SizedBox(height: 12),

                          // Value
                          _buildDetailRow(
                            'Amount',
                            '$formattedValue ${network.nativeSymbol}',
                          ),

                          if (gasLimit != null && gasLimit!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow('Gas Limit', gasLimit!),
                          ],

                          if (hasData) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Data',
                              '${data!.substring(0, data!.length > 20 ? 20 : data!.length)}...',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onApprove,
                        child: const Text('Confirm'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Show transaction request sheet
  static Future<bool?> show(
    BuildContext context, {
    required String dappName,
    required AbcNetwork network,
    required String from,
    required String to,
    required String value,
    String? data,
    String? gasLimit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionRequestSheet(
        dappName: dappName,
        network: network,
        from: from,
        to: to,
        value: value,
        data: data,
        gasLimit: gasLimit,
        onCancel: () => Navigator.of(context).pop(false),
        onApprove: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

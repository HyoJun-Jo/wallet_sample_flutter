import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/enums/abc_network.dart';

/// Sign Request Sheet
///
/// Shows dApp sign request with message content
/// Supports EIP-712 TypedData formatting
class SignRequestSheet extends StatelessWidget {
  final String dappName;
  final AbcNetwork network;
  final String message;
  final VoidCallback onCancel;
  final VoidCallback onApprove;

  const SignRequestSheet({
    super.key,
    required this.dappName,
    required this.network,
    required this.message,
    required this.onCancel,
    required this.onApprove,
  });

  /// Check if message is EIP-712 TypedData
  bool get _isTypedData {
    try {
      final data = jsonDecode(message);
      return data is Map &&
          (data.containsKey('domain') ||
              data.containsKey('primaryType') ||
              data.containsKey('types'));
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Sign',
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
                    Center(
                      child: Text(
                        _isTypedData ? 'Typed Data Request' : 'Signature Request',
                        style: const TextStyle(
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
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 8),
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

                    // Message section - TypedData or Plain
                    _isTypedData ? _buildTypedDataView() : _buildPlainMessageView(),

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
                        child: const Text('Sign'),
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

  /// Build plain message view
  Widget _buildPlainMessageView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build formatted TypedData view for EIP-712
  Widget _buildTypedDataView() {
    try {
      final typedData = jsonDecode(message);
      final domain = typedData['domain'] as Map<String, dynamic>?;
      final messageData = typedData['message'] as Map<String, dynamic>?;
      final primaryType = typedData['primaryType'] as String?;

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user,
                      color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'EIP-712 Typed Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Domain info
            if (domain != null) ...[
              _buildTypedDataSection(
                'Domain',
                Icons.domain,
                [
                  if (domain['name'] != null)
                    _buildTypedDataRow('Name', domain['name'].toString()),
                  if (domain['version'] != null)
                    _buildTypedDataRow('Version', domain['version'].toString()),
                  if (domain['chainId'] != null)
                    _buildTypedDataRow('Chain ID', domain['chainId'].toString()),
                  if (domain['verifyingContract'] != null)
                    _buildTypedDataRow(
                      'Contract',
                      _shortenAddress(domain['verifyingContract'].toString()),
                    ),
                ],
              ),
            ],

            // Primary Type
            if (primaryType != null)
              _buildTypedDataSection(
                'Primary Type',
                Icons.category,
                [_buildTypedDataRow('Type', primaryType)],
              ),

            // Message content
            if (messageData != null)
              _buildTypedDataSection(
                'Message',
                Icons.message,
                messageData.entries.map((e) => _buildTypedDataRow(
                  e.key,
                  _formatValue(e.value),
                )).toList(),
              ),

            // Raw JSON (collapsible)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                'Raw JSON',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade50,
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(typedData),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildPlainMessageView();
    }
  }

  Widget _buildTypedDataSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ...children,
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildTypedDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 14) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  String _formatValue(dynamic value) {
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  /// Show sign request sheet
  static Future<bool?> show(
    BuildContext context, {
    required String dappName,
    required AbcNetwork network,
    required String message,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => SignRequestSheet(
        dappName: dappName,
        network: network,
        message: message,
        onCancel: () => Navigator.of(context).pop(false),
        onApprove: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

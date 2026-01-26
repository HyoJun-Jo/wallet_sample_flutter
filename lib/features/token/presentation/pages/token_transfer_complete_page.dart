import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/utils/wei_utils.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/entities/token_transfer.dart';

/// Token transfer complete page - shows transaction result
class TokenTransferCompletePage extends StatelessWidget {
  final TokenTransferData transferData;
  final TokenTransferResult result;
  final String walletAddress;
  final TokenInfo? token;
  final String? amount;

  const TokenTransferCompletePage({
    super.key,
    required this.transferData,
    required this.result,
    required this.walletAddress,
    this.token,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final chainRepository = sl<ChainRepository>();
    final chain = chainRepository.getByNetwork(transferData.network);
    final isNative = token?.isNative ?? true;
    final symbol = isNative ? (chain?.symbol ?? 'ETH') : (token?.symbol ?? 'Token');
    final decimals = chain?.decimals ?? 18;

    // Calculate gas fee
    final gasLimit = WeiUtils.parseHex(transferData.gasLimit);
    final maxFeePerGas = WeiUtils.parseHex(transferData.maxFeePerGas);
    final gasFee = gasLimit * maxFeePerGas;
    final gasFeeFormatted = WeiUtils.fromWei(gasFee, decimals);
    final nativeSymbol = chain?.symbol ?? 'ETH';

    // Get recipient address
    final toAddress = isNative ? transferData.to : _extractToAddress(transferData.data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Success icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Transfer Complete',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Your transaction has been submitted',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Amount
                    if (amount != null)
                      _buildInfoCard(
                        context,
                        label: 'Amount',
                        value: '$amount $symbol',
                        icon: Icons.paid,
                      ),
                    const SizedBox(height: 12),

                    // From
                    _buildInfoCard(
                      context,
                      label: 'From',
                      value: walletAddress,
                      icon: Icons.account_balance_wallet,
                      copyable: true,
                    ),
                    const SizedBox(height: 12),

                    // To
                    _buildInfoCard(
                      context,
                      label: 'To',
                      value: toAddress,
                      icon: Icons.person,
                      copyable: true,
                    ),
                    const SizedBox(height: 12),

                    // Transaction Hash
                    _buildInfoCard(
                      context,
                      label: 'Transaction Hash',
                      value: result.transactionHash,
                      icon: Icons.tag,
                      copyable: true,
                    ),
                    const SizedBox(height: 12),

                    // Network
                    _buildInfoCard(
                      context,
                      label: 'Network',
                      value: chain?.name ?? transferData.network,
                      icon: Icons.public,
                    ),
                    const SizedBox(height: 12),

                    // Gas Fee
                    _buildInfoCard(
                      context,
                      label: 'Gas Fee',
                      value: '$gasFeeFormatted $nativeSymbol',
                      icon: Icons.local_gas_station,
                    ),
                    const SizedBox(height: 12),

                    // Status (always "Submitted" for new transactions)
                    _buildInfoCard(
                      context,
                      label: 'Status',
                      value: 'Submitted',
                      icon: Icons.info_outline,
                      valueColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // View on Explorer button
                  if (_getExplorerUrl(result.transactionHash).isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openExplorer(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View on Explorer'),
                    ),
                  const SizedBox(height: 12),

                  // Done button
                  ElevatedButton(
                    onPressed: () => context.go('/main'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16),
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

  Widget _buildInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool copyable = false,
    Color? valueColor,
  }) {
    final displayValue = value.length > 42 ? AddressUtils.shorten(value) : value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: valueColor,
                    fontWeight: valueColor != null ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  String _extractToAddress(String data) {
    if (data.length < 74) return 'Unknown';
    try {
      final addressHex = data.substring(34, 74);
      return '0x$addressHex';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getExplorerUrl(String txHash) {
    final chainRepository = sl<ChainRepository>();
    final chain = chainRepository.getByNetwork(transferData.network);
    if (chain == null || chain.explorerDetailUrl.isEmpty) return '';

    // explorerDetailUrl format: "https://etherscan.io/tx/"
    return '${chain.explorerDetailUrl}$txHash';
  }

  Future<void> _openExplorer(BuildContext context) async {
    final url = _getExplorerUrl(result.transactionHash);
    developer.log('[TokenTransferComplete] Explorer URL: $url', name: 'TokenTransferComplete');
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open explorer')),
        );
      }
    }
  }
}

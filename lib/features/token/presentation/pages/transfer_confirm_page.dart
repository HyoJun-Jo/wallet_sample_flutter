import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/wei_utils.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/entities/transfer.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_event.dart';
import '../bloc/transfer_state.dart';

/// Transfer confirmation page - Figma aligned design
class TransferConfirmPage extends StatefulWidget {
  final TransferData transferData;
  final TransferParams transferParams;
  final String walletAddress;
  final TokenInfo? token;

  const TransferConfirmPage({
    super.key,
    required this.transferData,
    required this.transferParams,
    required this.walletAddress,
    this.token,
  });

  @override
  State<TransferConfirmPage> createState() => _TransferConfirmPageState();
}

class _TransferConfirmPageState extends State<TransferConfirmPage> {
  bool _isDataExpanded = false;

  TransferData get transferData => widget.transferData;
  TransferParams get transferParams => widget.transferParams;
  TokenInfo? get token => widget.token;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state is TransferCompleted) {
          final chainRepository = sl<ChainRepository>();
          final chain = chainRepository.getByNetwork(transferData.network);
          final decimals = chain?.decimals ?? 18;
          final isNative = token?.isNative ?? true;

          final valueWei = WeiUtils.parseHex(transferData.value);

          context.go('/transfer/complete', extra: {
            'transferData': transferData,
            'result': state.result,
            'walletAddress': widget.walletAddress,
            'token': token,
            'amount': isNative ? WeiUtils.fromWei(valueWei, decimals) : null,
          });
        } else if (state is TransferError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final chainRepository = sl<ChainRepository>();
    final chain = chainRepository.getByNetwork(transferData.network);
    final isNative = token?.isNative ?? true;
    final decimals = chain?.decimals ?? 18;
    final symbol = chain?.symbol ?? 'ETH';

    // Calculate values
    final valueWei = WeiUtils.parseHex(transferData.value);
    final gasLimit = WeiUtils.parseHex(transferData.gasLimit);
    final maxFeePerGas = WeiUtils.parseHex(transferData.maxFeePerGas);
    final maxPriorityFeePerGas = WeiUtils.parseHex(transferData.maxPriorityFeePerGas);

    final gasFee = gasLimit * maxFeePerGas;
    final valueFormatted = WeiUtils.fromWei(valueWei, decimals);
    final gasFeeFormatted = WeiUtils.fromWei(gasFee, decimals);

    // USD values (mock for now)
    final valueUsd = token?.priceUsd != null
        ? double.tryParse(valueFormatted)! * token!.priceUsd!
        : null;
    final gasFeeUsd = chain != null ? 2.72 : null; // Mock value

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Amount Display
                    _buildAmountSection(
                      valueFormatted: isNative ? valueFormatted : transferParams.amount,
                      symbol: isNative ? symbol : (token?.symbol ?? 'Token'),
                      valueUsd: valueUsd,
                    ),
                    const SizedBox(height: 16),

                    // From → To
                    _buildFromToSection(
                      fromAddress: widget.walletAddress,
                      toAddress: isNative ? transferData.to : transferParams.toAddress,
                    ),
                    const SizedBox(height: 12),

                    // Network
                    _buildNetworkSection(chain?.name ?? transferData.network),
                    const SizedBox(height: 12),

                    // Network Fee
                    _buildNetworkFeeSection(
                      gasFeeFormatted: gasFeeFormatted,
                      symbol: symbol,
                      gasFeeUsd: gasFeeUsd,
                      maxFeePerGas: maxFeePerGas,
                      maxPriorityFeePerGas: maxPriorityFeePerGas,
                    ),
                    const SizedBox(height: 12),

                    // Data Section
                    _buildDataSection(),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection({
    required String valueFormatted,
    required String symbol,
    double? valueUsd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Token Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: token?.logo != null && token!.logo!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      token!.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultIcon(),
                    ),
                  )
                : _buildDefaultIcon(),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$valueFormatted $symbol',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (valueUsd != null)
                Text(
                  FormatUtils.formatUsd(valueUsd),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      child: Text(
        token?.symbol.isNotEmpty == true ? token!.symbol[0] : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildFromToSection({
    required String fromAddress,
    required String toAddress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // From
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AddressUtils.shorten(fromAddress),
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Arrow
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16),
          ),
          // To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'To',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AddressUtils.shorten(toAddress),
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSection(String networkName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Network',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_exchange, size: 12),
              ),
              const SizedBox(width: 4),
              Text(networkName, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkFeeSection({
    required String gasFeeFormatted,
    required String symbol,
    double? gasFeeUsd,
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
  }) {
    final maxFeeGwei = WeiUtils.toGwei(maxFeePerGas);
    final priorityFeeGwei = WeiUtils.toGwei(maxPriorityFeePerGas);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Fee',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Estimated Gas Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Gas Fee', style: TextStyle(fontSize: 14)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$gasFeeFormatted $symbol',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (gasFeeUsd != null)
                    Text(
                      FormatUtils.formatUsd(gasFeeUsd),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Speed
          _buildFeeRow('Speed', 'High  15~30 sec'),

          // Max Fee
          _buildFeeRow('Max Fee', '$maxFeeGwei Gwei'),

          // Priority Fee
          _buildFeeRow('Priority Fee', '$priorityFeeGwei Gwei'),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          GestureDetector(
            onTap: () => setState(() => _isDataExpanded = !_isDataExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _copyToClipboard(transferData.data),
                      child: Icon(Icons.copy, size: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isDataExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isDataExpanded) ...[
            const SizedBox(height: 12),
            // Function
            const Text(
              'Function: Transfer',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Hex Data
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transferData.data,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return BlocBuilder<TransferBloc, TransferState>(
      builder: (context, state) {
        final isLoading = state is TransferLoading;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cancel Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sign Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<TransferBloc>().add(
                              TransferRequested(params: transferParams),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

}

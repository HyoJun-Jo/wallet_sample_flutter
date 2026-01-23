import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/entities/transfer.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_event.dart';
import '../bloc/transfer_state.dart';

/// Transfer confirmation page - shows transaction details and handles signing via BLoC
class TransferConfirmPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state is TransferCompleted) {
          // Navigate to transfer complete page
          final chainRepository = sl<ChainRepository>();
          final chain = chainRepository.getByNetwork(transferData.network);
          final decimals = chain?.decimals ?? 18;
          final isNative = token?.isNative ?? true;

          final valueWei = BigInt.tryParse(
            transferData.value.startsWith('0x')
                ? transferData.value.substring(2)
                : transferData.value,
            radix: 16,
          ) ?? BigInt.zero;

          context.go('/transfer/complete', extra: {
            'transferData': transferData,
            'result': state.result,
            'walletAddress': walletAddress,
            'token': token,
            'amount': isNative ? _formatWei(valueWei, decimals) : null,
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
      child: _TransferConfirmContent(
        transferData: transferData,
        transferParams: transferParams,
        walletAddress: walletAddress,
        token: token,
      ),
    );
  }

  String _formatWei(BigInt wei, int decimals) {
    if (wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(decimals);
    final intPart = wei ~/ divisor;
    final decPart = wei % divisor;

    if (decPart == BigInt.zero) {
      return intPart.toString();
    }

    final decStr = decPart.toString().padLeft(decimals, '0');
    final trimmed = decStr.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) {
      return intPart.toString();
    }
    return '$intPart.${trimmed.length > 6 ? trimmed.substring(0, 6) : trimmed}';
  }
}

class _TransferConfirmContent extends StatelessWidget {
  final TransferData transferData;
  final TransferParams transferParams;
  final String walletAddress;
  final TokenInfo? token;

  const _TransferConfirmContent({
    required this.transferData,
    required this.transferParams,
    required this.walletAddress,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final chainRepository = sl<ChainRepository>();
    final chain = chainRepository.getByNetwork(transferData.network);
    final isNative = token?.isNative ?? true;

    // Calculate values for display
    final valueWei = BigInt.tryParse(
      transferData.value.startsWith('0x')
          ? transferData.value.substring(2)
          : transferData.value,
      radix: 16,
    ) ?? BigInt.zero;

    final gasLimit = BigInt.tryParse(
      transferData.gasLimit.startsWith('0x')
          ? transferData.gasLimit.substring(2)
          : transferData.gasLimit,
      radix: 16,
    ) ?? BigInt.zero;

    final maxFeePerGas = BigInt.tryParse(
      transferData.maxFeePerGas.startsWith('0x')
          ? transferData.maxFeePerGas.substring(2)
          : transferData.maxFeePerGas,
      radix: 16,
    ) ?? BigInt.zero;

    final gasFee = gasLimit * maxFeePerGas;
    final decimals = chain?.decimals ?? 18;
    final symbol = chain?.symbol ?? 'ETH';

    final valueFormatted = _formatWei(valueWei, decimals);
    final gasFeeFormatted = _formatWei(gasFee, decimals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transaction'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Token/Amount info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Sending',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isNative
                                ? '$valueFormatted $symbol'
                                : '${transferParams.amount} ${token?.symbol ?? "Token"}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isNative && token != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              token!.name,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // From
                    _buildInfoRow(
                      'From',
                      AddressUtils.shorten(walletAddress),
                      Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),

                    // To
                    _buildInfoRow(
                      'To',
                      AddressUtils.shorten(
                        isNative ? transferData.to : transferParams.toAddress,
                      ),
                      Icons.person,
                    ),
                    const SizedBox(height: 12),

                    // Network
                    _buildInfoRow(
                      'Network',
                      chain?.name ?? transferData.network,
                      Icons.public,
                    ),
                    const SizedBox(height: 24),

                    // Gas fee section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction Fee',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gas Limit',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(gasLimit.toString()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gas Price',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text('${_formatGwei(maxFeePerGas)} Gwei'),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Estimated Fee',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$gasFeeFormatted $symbol',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confirm button
            BlocBuilder<TransferBloc, TransferState>(
              builder: (context, state) {
                final isLoading = state is TransferLoading;
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<TransferBloc>().add(
                              TransferRequested(params: transferParams),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Confirm & Sign',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
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
          Column(
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
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWei(BigInt wei, int decimals) {
    if (wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(decimals);
    final intPart = wei ~/ divisor;
    final decPart = wei % divisor;

    if (decPart == BigInt.zero) {
      return intPart.toString();
    }

    final decStr = decPart.toString().padLeft(decimals, '0');
    final trimmed = decStr.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) {
      return intPart.toString();
    }
    return '$intPart.${trimmed.length > 6 ? trimmed.substring(0, 6) : trimmed}';
  }

  String _formatGwei(BigInt wei) {
    final gwei = wei ~/ BigInt.from(10).pow(9);
    return gwei.toString();
  }
}

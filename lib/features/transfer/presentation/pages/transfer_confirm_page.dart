import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/chain_service.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../signing/presentation/bloc/signing_bloc.dart';
import '../../../signing/presentation/bloc/signing_event.dart';
import '../../../signing/presentation/bloc/signing_state.dart';
import '../../../token/domain/entities/token_info.dart';
import '../../domain/entities/transfer.dart';

/// Transfer confirmation page - shows transaction details and handles signing
class TransferConfirmPage extends StatelessWidget {
  final TransferData transferData;
  final String walletAddress;
  final TokenInfo? token;

  const TransferConfirmPage({
    super.key,
    required this.transferData,
    required this.walletAddress,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SigningBloc>(),
      child: _TransferConfirmView(
        transferData: transferData,
        walletAddress: walletAddress,
        token: token,
      ),
    );
  }
}

class _TransferConfirmView extends StatelessWidget {
  final TransferData transferData;
  final String walletAddress;
  final TokenInfo? token;

  const _TransferConfirmView({
    required this.transferData,
    required this.walletAddress,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final chainService = sl<ChainService>();
    final chain = chainService.getByNetwork(transferData.network);
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
        child: BlocConsumer<SigningBloc, SigningState>(
          listener: (context, state) {
            if (state is SigningCompleted) {
              // Transaction signed, now send it
              // Use serializedTx (full RLP-encoded signed tx), not rawTx (just hash)
              final signedTx = state.result.serializedTx ?? state.result.rawTx;
              if (signedTx != null) {
                context.read<SigningBloc>().add(SendTransactionRequested(
                      network: transferData.network,
                      signedTx: signedTx,
                    ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signing completed but no serializedTx returned')),
                );
              }
            } else if (state is TransactionSent) {
              // Navigate to transfer complete page
              context.go('/transfer/complete', extra: {
                'transferData': transferData,
                'result': TransferResult(
                  txHash: state.txHash,
                  status: TransferStatus.submitted,
                ),
                'walletAddress': walletAddress,
                'token': token,
                'amount': isNative ? valueFormatted : null,
              });
            } else if (state is SigningError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return Column(
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
                                    : token?.symbol ?? 'Token',
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
                            isNative ? transferData.to : _extractToAddress(transferData.data),
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: state is SigningLoading
                        ? null
                        : () => _onConfirm(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: state is SigningLoading
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
                ),
              ],
            );
          },
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

  void _onConfirm(BuildContext context) {
    // Use EIP-1559 signing
    context.read<SigningBloc>().add(SignEip1559Requested(
          accountId: walletAddress,
          network: transferData.network,
          from: transferData.from,
          to: transferData.to,
          value: transferData.value,
          data: transferData.data,
          nonce: transferData.nonce,
          gasLimit: transferData.gasLimit,
          maxFeePerGas: transferData.maxFeePerGas,
          maxPriorityFeePerGas: transferData.maxPriorityFeePerGas,
        ));
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
    // Trim trailing zeros
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

  /// Extract recipient address from ERC-20 transfer data
  String _extractToAddress(String data) {
    if (data.length < 74) return 'Unknown';
    // transfer(address,uint256) = 0xa9059cbb + address (32 bytes) + amount (32 bytes)
    // Address is at bytes 4-36, but padded to 32 bytes, so actual address is bytes 16-36 (last 20 bytes)
    try {
      final addressHex = data.substring(34, 74);
      return '0x$addressHex';
    } catch (_) {
      return 'Unknown';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../../shared/signing/domain/entities/signing_entities.dart';
import '../../../../shared/signing/domain/repositories/signing_repository.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../../domain/entities/token_info.dart';
import '../../domain/entities/transfer.dart';

/// Transfer confirmation page - shows transaction details and handles signing
class TransferConfirmPage extends StatefulWidget {
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
  State<TransferConfirmPage> createState() => _TransferConfirmPageState();
}

class _TransferConfirmPageState extends State<TransferConfirmPage> {
  final SigningRepository _signingRepository = sl<SigningRepository>();
  final TransactionRepository _transactionRepository = sl<TransactionRepository>();

  bool _isLoading = false;
  String? _error;

  Future<void> _onConfirm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Sign transaction using SigningRepository
      final signResult = await _signingRepository.signTransaction(
        params: SignTransactionParams(
          network: widget.transferData.network,
          from: widget.transferData.from,
          to: widget.transferData.to,
          value: widget.transferData.value,
          data: widget.transferData.data,
          nonce: widget.transferData.nonce,
          gasLimit: widget.transferData.gasLimit,
          maxFeePerGas: widget.transferData.maxFeePerGas,
          maxPriorityFeePerGas: widget.transferData.maxPriorityFeePerGas,
          type: SignType.eip1559,
        ),
      );

      final signedTx = signResult.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
          return null;
        },
        (result) => result.serializedTx.isNotEmpty ? result.serializedTx : result.rawTx,
      );

      if (signedTx == null || signedTx.isEmpty) {
        if (_error == null) {
          setState(() {
            _error = 'Signing completed but no serializedTx returned';
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Send transaction
      final sendResult = await _transactionRepository.sendTransaction(
        params: SendTransactionParams(
          network: widget.transferData.network,
          signedSerializeTx: signedTx,
        ),
      );

      sendResult.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (result) {
          // Navigate to transfer complete page
          if (mounted) {
            final isNative = widget.token?.isNative ?? true;
            final chainRepository = sl<ChainRepository>();
            final chain = chainRepository.getByNetwork(widget.transferData.network);
            final decimals = chain?.decimals ?? 18;

            final valueWei = BigInt.tryParse(
              widget.transferData.value.startsWith('0x')
                  ? widget.transferData.value.substring(2)
                  : widget.transferData.value,
              radix: 16,
            ) ?? BigInt.zero;

            context.go('/transfer/complete', extra: {
              'transferData': widget.transferData,
              'result': TransferResult(
                txHash: result.transactionHash,
                status: TransferStatus.submitted,
              ),
              'walletAddress': widget.walletAddress,
              'token': widget.token,
              'amount': isNative ? _formatWei(valueWei, decimals) : null,
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chainRepository = sl<ChainRepository>();
    final chain = chainRepository.getByNetwork(widget.transferData.network);
    final isNative = widget.token?.isNative ?? true;

    // Calculate values for display
    final valueWei = BigInt.tryParse(
      widget.transferData.value.startsWith('0x')
          ? widget.transferData.value.substring(2)
          : widget.transferData.value,
      radix: 16,
    ) ?? BigInt.zero;

    final gasLimit = BigInt.tryParse(
      widget.transferData.gasLimit.startsWith('0x')
          ? widget.transferData.gasLimit.substring(2)
          : widget.transferData.gasLimit,
      radix: 16,
    ) ?? BigInt.zero;

    final maxFeePerGas = BigInt.tryParse(
      widget.transferData.maxFeePerGas.startsWith('0x')
          ? widget.transferData.maxFeePerGas.substring(2)
          : widget.transferData.maxFeePerGas,
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
                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),

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
                                : widget.token?.symbol ?? 'Token',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isNative && widget.token != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.token!.name,
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
                      AddressUtils.shorten(widget.walletAddress),
                      Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),

                    // To
                    _buildInfoRow(
                      'To',
                      AddressUtils.shorten(
                        isNative ? widget.transferData.to : _extractToAddress(widget.transferData.data),
                      ),
                      Icons.person,
                    ),
                    const SizedBox(height: 12),

                    // Network
                    _buildInfoRow(
                      'Network',
                      chain?.name ?? widget.transferData.network,
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
                onPressed: _isLoading ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
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

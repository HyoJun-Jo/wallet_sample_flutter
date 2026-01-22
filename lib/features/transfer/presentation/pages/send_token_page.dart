import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../token/domain/entities/token_info.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_event.dart';
import '../bloc/transfer_state.dart';

/// Send token page
class SendTokenPage extends StatefulWidget {
  final String walletAddress;
  final TokenInfo? token;

  const SendTokenPage({
    super.key,
    required this.walletAddress,
    this.token,
  });

  @override
  State<SendTokenPage> createState() => _SendTokenPageState();
}

class _SendTokenPageState extends State<SendTokenPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toAddressController;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to self-transfer for testing
    _toAddressController = TextEditingController(text: widget.walletAddress);
  }

  @override
  void dispose() {
    _toAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSend() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<TransferBloc>().add(TransferDataRequested(
            fromAddress: widget.walletAddress,
            toAddress: _toAddressController.text.trim(),
            amount: _amountController.text.trim(),
            contractAddress: widget.token?.contractAddress ?? '',
            network: widget.token?.network ?? 'ethereum',
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send ${widget.token?.symbol ?? 'Token'}'),
      ),
      body: SafeArea(
        child: BlocConsumer<TransferBloc, TransferState>(
          listener: (context, state) {
          if (state is TransferCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transfer completed: ${state.result.txHash}')),
            );
            context.pop();
          } else if (state is TransferError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TransferDataReady) {
            // Navigate to transfer confirm page
            context.push(
              '/transfer/confirm',
              extra: {
                'transferData': state.transferData,
                'walletAddress': widget.walletAddress,
                'token': widget.token,
              },
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Token information
                  if (widget.token != null) _buildTokenInfo(),
                  const SizedBox(height: 24),

                  // From address
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
                          'From Address',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AddressUtils.shorten(widget.walletAddress),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // To address input
                  TextFormField(
                    controller: _toAddressController,
                    decoration: InputDecoration(
                      labelText: 'To Address',
                      hintText: '0x...',
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _toAddressController.text = data!.text!;
                          }
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter recipient address';
                      }
                      if (!value.startsWith('0x') || value.length != 42) {
                        return 'Invalid address format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.0',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                      suffixText: widget.token?.symbol ?? '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                  if (widget.token != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _amountController.text =
                              widget.token!.formattedBalance;
                        },
                        child: Text(
                          'Max: ${widget.token!.formattedBalance} ${widget.token!.symbol}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Send button
                  ElevatedButton(
                    onPressed: state is TransferLoading ? null : _onSend,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state is TransferLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Send',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildTokenInfo() {
    final token = widget.token!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                token.logo != null ? NetworkImage(token.logo!) : null,
            child: token.logo == null
                ? Text(
                    token.symbol.isNotEmpty ? token.symbol[0] : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Balance: ${token.formattedBalance} ${token.symbol}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

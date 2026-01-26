import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/network_utils.dart';
import '../../domain/entities/token_info.dart';
import '../bloc/token_transfer_bloc.dart';
import '../bloc/token_transfer_event.dart';
import '../bloc/token_transfer_state.dart';

/// Token transfer input page - first step of transfer flow
class TokenTransferInputPage extends StatefulWidget {
  final String walletAddress;
  final TokenInfo? token;

  const TokenTransferInputPage({
    super.key,
    required this.walletAddress,
    this.token,
  });

  @override
  State<TokenTransferInputPage> createState() => _TokenTransferInputPageState();
}

class _TokenTransferInputPageState extends State<TokenTransferInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _toAddressController = TextEditingController();
  final _amountController = TextEditingController();
  bool _addToAddressBook = false;

  @override
  void dispose() {
    _toAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<TokenTransferBloc>().add(PrepareTokenTransfer(
            fromAddress: widget.walletAddress,
            toAddress: _toAddressController.text.trim(),
            amount: _amountController.text.trim(),
            contractAddress: widget.token?.contractAddress ?? '',
            network: widget.token?.network ?? 'ethereum',
          ));
    }
  }

  void _onPrevious() {
    context.pop();
  }

  Future<void> _onPaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _toAddressController.text = data!.text!;
    }
  }

  void _onMax() {
    if (widget.token != null) {
      _amountController.text = widget.token!.formattedBalance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<TokenTransferBloc, TokenTransferState>(
          listener: (context, state) {
            if (state is TokenTransferCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Transfer completed: ${state.result.transactionHash}')),
              );
              context.pop();
            } else if (state is TokenTransferError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            } else if (state is TokenTransferDataReady) {
              context.push(
                '/transfer/confirm',
                extra: {
                  'transferData': state.transferData,
                  'transferParams': state.transferParams,
                  'walletAddress': widget.walletAddress,
                  'token': widget.token,
                },
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is TokenTransferLoading;
            return Column(
              children: [
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Token Info
                          _buildTokenInfo(),
                          const SizedBox(height: 24),
                          // To Address Field
                          _buildToField(),
                          const SizedBox(height: 12),
                          // Add to Address Book
                          _buildAddressBookCheckbox(),
                          const SizedBox(height: 24),
                          // Amount Field
                          _buildAmountField(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Buttons
                _buildBottomButtons(isLoading),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTokenInfo() {
    final token = widget.token;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                        token.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultTokenIcon(),
                      ),
                    )
                  : _buildDefaultTokenIcon(),
            ),
            const SizedBox(width: 12),
            // Token Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token?.symbol ?? 'Token',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.currency_exchange, size: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NetworkUtils.formatDisplayName(token?.network ?? 'ethereum'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultTokenIcon() {
    return Center(
      child: Text(
        widget.token?.symbol.isNotEmpty == true ? widget.token!.symbol[0] : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildToField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with paste icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'To',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _onPaste,
              child: Icon(Icons.copy_all, color: Colors.grey.shade600, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Input Field
        TextFormField(
          controller: _toAddressController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Please enter recipient's address.",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            suffixIcon: GestureDetector(
              onTap: _onPaste,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.content_paste, color: Colors.grey.shade600, size: 18),
              ),
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
      ],
    );
  }

  Widget _buildAddressBookCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _addToAddressBook = !_addToAddressBook),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _addToAddressBook ? Theme.of(context).primaryColor : Colors.transparent,
              border: Border.all(
                color: _addToAddressBook ? Theme.of(context).primaryColor : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _addToAddressBook
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Add to Address Book',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final token = widget.token;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Amount',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Input Field
        TextFormField(
          controller: _amountController,
          style: const TextStyle(fontSize: 16),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: token != null
                ? 'Balance • ${token.formattedBalance} ${token.symbol}'
                : 'Enter amount',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            suffixIcon: GestureDetector(
              onTap: _onMax,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Max',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
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
      ],
    );
  }

  Widget _buildBottomButtons(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _onPrevious,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left, size: 16),
                    SizedBox(width: 4),
                    Text('Previous', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Next Button
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _onNext,
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Next', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

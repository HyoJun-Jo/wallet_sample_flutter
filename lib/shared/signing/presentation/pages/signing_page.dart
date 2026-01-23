import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/sign_request.dart';
import '../bloc/signing_bloc.dart';
import '../bloc/signing_event.dart';
import '../bloc/signing_state.dart';

/// Signing page
class SigningPage extends StatefulWidget {
  final String accountId;
  final String network;
  final String? data;
  final MessageType msgType;

  const SigningPage({
    super.key,
    required this.accountId,
    required this.network,
    this.data,
    this.msgType = MessageType.message,
  });

  @override
  State<SigningPage> createState() => _SigningPageState();
}

class _SigningPageState extends State<SigningPage> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _messageController.text = widget.data!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onRequestSign() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter data to sign')),
      );
      return;
    }

    final msg = _messageController.text.trim();

    switch (widget.msgType) {
      case MessageType.typedData:
        context.read<SigningBloc>().add(SignTypedDataRequested(
              accountId: widget.accountId,
              network: widget.network,
              typeDataMsg: msg,
            ));
        break;
      case MessageType.hash:
        context.read<SigningBloc>().add(SignHashRequested(
              accountId: widget.accountId,
              network: widget.network,
              hash: msg,
            ));
        break;
      default:
        context.read<SigningBloc>().add(SignMessageRequested(
              msgType: widget.msgType,
              accountId: widget.accountId,
              network: widget.network,
              msg: msg,
            ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: SafeArea(
        child: BlocConsumer<SigningBloc, SigningState>(
          listener: (context, state) {
          if (state is SigningCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signing completed: ${state.result.signature}')),
            );
            context.pop(state.result);
          } else if (state is SigningError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return _buildInputView(state);
        },
        ),
      ),
    );
  }

  Widget _buildInputView(SigningState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Information message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDescription(),
                    style: TextStyle(color: Colors.purple.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account ID
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.accountId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Network
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
                  'Network',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.network,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Message input or TypedData display
          if (widget.msgType == MessageType.typedData && widget.data != null)
            _buildTypedDataView()
          else
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: _getInputLabel(),
                hintText: _getInputHint(),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 32),

          // Sign button
          ElevatedButton(
            onPressed: state is SigningLoading ? null : _onRequestSign,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: state is SigningLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Sign',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.msgType) {
      case MessageType.transaction:
        return 'Transaction Signing';
      case MessageType.message:
        return 'Message Signing';
      case MessageType.typedData:
        return 'Typed Data Signing';
      case MessageType.hash:
        return 'Hash Signing';
    }
  }

  String _getDescription() {
    switch (widget.msgType) {
      case MessageType.transaction:
        return 'Sign transaction using MPC technology.';
      case MessageType.message:
        return 'Sign message using MPC technology.';
      case MessageType.typedData:
        return 'Sign EIP-712 Typed Data using MPC technology.';
      case MessageType.hash:
        return 'Sign hash using MPC technology.';
    }
  }

  String _getInputLabel() {
    switch (widget.msgType) {
      case MessageType.transaction:
        return 'Transaction Data';
      case MessageType.message:
        return 'Message';
      case MessageType.typedData:
        return 'Typed Data (JSON)';
      case MessageType.hash:
        return 'Hash';
    }
  }

  String _getInputHint() {
    switch (widget.msgType) {
      case MessageType.transaction:
        return 'Enter transaction data';
      case MessageType.message:
        return 'Enter message to sign';
      case MessageType.typedData:
        return 'Enter EIP-712 typed data JSON';
      case MessageType.hash:
        return 'Enter hash to sign';
    }
  }

  /// Build formatted TypedData view for EIP-712
  Widget _buildTypedDataView() {
    try {
      final typedData = jsonDecode(widget.data!);
      final domain = typedData['domain'] as Map<String, dynamic>?;
      final message = typedData['message'] as Map<String, dynamic>?;
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
            if (message != null)
              _buildTypedDataSection(
                'Message',
                Icons.message,
                message.entries.map((e) => _buildTypedDataRow(
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
      // Fallback to text field if JSON parsing fails
      return TextFormField(
        controller: _messageController,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: _getInputLabel(),
          hintText: _getInputHint(),
          alignLabelWithHint: true,
          border: const OutlineInputBorder(),
        ),
      );
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
            width: 100,
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
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction_history.dart';

class HistoryItem extends StatelessWidget {
  final TransactionHistory transaction;
  final VoidCallback? onTap;

  const HistoryItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isContractCall = transaction.type == TransactionType.contractCall;
    final isIncoming = transaction.direction == TransactionDirection.incoming;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isContractCall
              ? Colors.blue.withValues(alpha: 0.3)
              : isIncoming
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildDirectionIcon(isContractCall, isIncoming),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDirectionLabel(isContractCall, isIncoming),
                    const SizedBox(height: 4),
                    _buildTitle(),
                    const SizedBox(height: 2),
                    _buildSubtitle(),
                  ],
                ),
              ),
              _buildTrailing(context, isContractCall, isIncoming),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionIcon(bool isContractCall, bool isIncoming) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    if (isContractCall) {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      iconColor = Colors.blue;
      icon = Icons.description_outlined;
    } else if (isIncoming) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      iconColor = Colors.green;
      icon = Icons.call_received;
    } else {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      iconColor = Colors.orange;
      icon = Icons.call_made;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildDirectionLabel(bool isContractCall, bool isIncoming) {
    Color bgColor;
    Color textColor;
    String label;

    if (isContractCall) {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue.shade700;
      label = 'Contract';
    } else if (isIncoming) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green.shade700;
      label = 'Received';
    } else {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange.shade700;
      label = 'Sent';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (transaction.type) {
      case TransactionType.coinTransfer:
        title = transaction.isIncoming ? 'Received' : 'Sent';
      case TransactionType.tokenTransfer:
        final symbol = transaction.tokenSymbol ?? 'Token';
        title = transaction.isIncoming ? 'Received $symbol' : 'Sent $symbol';
      case TransactionType.nftTransfer:
        final name = transaction.tokenName ?? 'NFT';
        title = transaction.isIncoming ? 'Received $name' : 'Sent $name';
      case TransactionType.contractCall:
        title = 'Contract Call';
    }
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  Widget _buildSubtitle() {
    final dateStr = _formatDate(transaction.timestamp);

    String subtitle = dateStr;

    if (transaction.network.isNotEmpty) {
      subtitle = '${_formatNetworkName(transaction.network)} • $dateStr';
    }

    return Text(
      subtitle,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 12,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy HH:mm').format(date);
  }

  Widget _buildTrailing(BuildContext context, bool isContractCall, bool isIncoming) {
    String valueText;
    String prefix;
    Color textColor;

    if (isContractCall) {
      final decimals = transaction.tokenDecimals ?? 18;
      final formattedValue = _formatTokenAmount(transaction.value, decimals);
      final symbol = transaction.tokenSymbol ?? '';
      valueText = '$formattedValue $symbol'.trim();
      prefix = '';
      textColor = Colors.blue.shade700;
    } else if (transaction.type == TransactionType.nftTransfer) {
      if (transaction.tokenName != null && transaction.tokenName!.isNotEmpty) {
        valueText = transaction.tokenName!;
        prefix = isIncoming ? '+' : '-';
      } else {
        valueText = '';
        prefix = '';
      }
      textColor = isIncoming ? Colors.green.shade700 : Colors.orange.shade700;
    } else {
      final decimals = transaction.tokenDecimals ?? 18;
      final formattedValue = _formatTokenAmount(transaction.value, decimals);
      final symbol = transaction.tokenSymbol ?? '';
      valueText = '$formattedValue $symbol'.trim();
      prefix = isIncoming ? '+' : '-';
      textColor = isIncoming ? Colors.green.shade700 : Colors.orange.shade700;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$prefix$valueText',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        _buildStatusBadge(),
      ],
    );
  }

  String _formatTokenAmount(String weiValue, int decimals) {
    try {
      final value = BigInt.tryParse(weiValue) ?? BigInt.zero;
      if (value == BigInt.zero) return '0';

      final divisor = BigInt.from(10).pow(decimals);
      final integerPart = value ~/ divisor;
      final fractionalPart = value % divisor;

      if (fractionalPart == BigInt.zero) {
        return _formatLargeNumber(integerPart.toDouble());
      }

      final fractionalStr = fractionalPart.toString().padLeft(decimals, '0');
      final trimmedFraction = fractionalStr.replaceAll(RegExp(r'0+$'), '');
      final displayFraction = trimmedFraction.length > 4
          ? trimmedFraction.substring(0, 4)
          : trimmedFraction;

      if (integerPart == BigInt.zero) {
        return '0.$displayFraction';
      }

      return '${_formatLargeNumber(integerPart.toDouble())}.$displayFraction';
    } catch (_) {
      return weiValue;
    }
  }

  String _formatLargeNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;

    switch (transaction.status.toLowerCase()) {
      case 'confirmed':
      case 'success':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Confirmed';
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Pending';
      case 'failed':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        text = 'Failed';
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = transaction.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatNetworkName(String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'ETH';
      case 'polygon':
        return 'MATIC';
      case 'binance':
      case 'bsc':
        return 'BNB';
      case 'arbitrum':
        return 'ARB';
      case 'optimism':
        return 'OP';
      case 'avalanche':
        return 'AVAX';
      default:
        return network.toUpperCase();
    }
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/networks.dart';
import '../../../../core/utils/address_utils.dart';
import '../../domain/entities/history_entry.dart';

class HistoryItem extends StatelessWidget {
  final HistoryEntry entry;
  final String walletAddress;
  final String? tokenLogo;
  final VoidCallback? onTap;

  const HistoryItem({
    super.key,
    required this.entry,
    this.walletAddress = '',
    this.tokenLogo,
    this.onTap,
  });

  bool get _isOutgoing {
    // Match SDK logic: check receiver side first
    // If receiver matches wallet → Receive, otherwise → Send
    if (walletAddress.isEmpty) {
      return entry.direction == HistoryDirection.outgoing;
    }
    return entry.to.toLowerCase() != walletAddress.toLowerCase();
  }

  String get _label {
    final isContractCall = entry.type == HistoryType.contractCall;
    final success = entry.status.toLowerCase() == 'confirmed';

    if (isContractCall) {
      return success ? 'Contract Call' : 'Contract Call Failed';
    }
    if (_isOutgoing) {
      return success ? 'Send' : 'Send Failed';
    }
    return success ? 'Receive' : 'Receive Failed';
  }

  void _openExplorer() async {
    final url = Networks.getTransactionUrl(entry.network, entry.hash);
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isContractCall = entry.type == HistoryType.contractCall;
    final isFailed = entry.status.toLowerCase() == 'failed';

    return InkWell(
      onTap: onTap ?? _openExplorer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            // Icon Container with Network Badge and Status
            _buildIconContainer(colorScheme, isContractCall, isFailed),
            const SizedBox(width: 12),

            // Transaction Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getAddressText(),
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount and Time
            _buildDetails(colorScheme, isContractCall),

            // Export Button
            const SizedBox(width: 8),
            IconButton(
              onPressed: _openExplorer,
              icon: Icon(
                Icons.open_in_new,
                size: 18,
                color: colorScheme.primary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(
    ColorScheme colorScheme,
    bool isContractCall,
    bool isFailed,
  ) {
    final networkIcon = Networks.getIcon(entry.network);
    final isTokenTransfer = entry.type == HistoryType.tokenTransfer;
    final isNftTransfer = entry.type == HistoryType.nftTransfer;
    final isCoinTransfer = entry.type == HistoryType.coinTransfer;

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: isContractCall
                  ? Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : tokenLogo != null
                      ? CachedNetworkImage(
                          imageUrl: tokenLogo!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildTokenPlaceholder(colorScheme),
                          errorWidget: (context, url, error) =>
                              _buildTokenPlaceholder(colorScheme),
                        )
                      : isCoinTransfer && networkIcon != null
                          ? CachedNetworkImage(
                              imageUrl: networkIcon,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _buildTokenPlaceholder(colorScheme),
                              errorWidget: (context, url, error) =>
                                  _buildTokenPlaceholder(colorScheme),
                            )
                          : _buildTokenPlaceholder(colorScheme),
            ),
          ),

          // Network Badge (bottom right) - show for token/NFT transfers
          if (networkIcon != null && (isTokenTransfer || isNftTransfer))
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: networkIcon,
                    width: 16,
                    height: 16,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Status Indicator (top left)
          if (!isContractCall || isFailed)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isFailed
                      ? Colors.red.withValues(alpha: 0.2)
                      : _isOutgoing
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isFailed
                      ? Icons.close
                      : _isOutgoing
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                  size: 10,
                  color: isFailed
                      ? Colors.red
                      : _isOutgoing
                          ? Colors.red
                          : Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTokenPlaceholder(ColorScheme colorScheme) {
    // For token transfers use token symbol, for coin transfers use network symbol
    final symbol = entry.tokenSymbol ?? Networks.getSymbol(entry.network);
    final displayLength = symbol.length >= 3 ? 3 : symbol.length;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        symbol.substring(0, displayLength).toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _getAddressText() {
    final isContractCall = entry.type == HistoryType.contractCall;

    if (isContractCall) {
      return 'App ${AddressUtils.shorten(entry.to)}';
    }
    if (_isOutgoing) {
      return 'To ${AddressUtils.shorten(entry.to)}';
    }
    return 'From ${AddressUtils.shorten(entry.from)}';
  }

  Widget _buildDetails(ColorScheme colorScheme, bool isContractCall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isContractCall && entry.tokenSymbol != null)
          Text(
            '${_isOutgoing ? '-' : '+'}${_formatAmount()} ${entry.tokenSymbol}',
            style: TextStyle(
              fontSize: 16,
              color: _isOutgoing ? Colors.red : Colors.green,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          _formatTime(entry.timestamp),
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatAmount() {
    final decimals = entry.tokenDecimals ?? 18;
    try {
      final value = BigInt.tryParse(entry.value) ?? BigInt.zero;
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
      return entry.value;
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

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}

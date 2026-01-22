import 'package:flutter/material.dart';
import '../../../../core/utils/network_utils.dart';
import '../../domain/entities/token_info.dart';

/// Token list item widget
class TokenListItem extends StatelessWidget {
  final TokenInfo token;
  final VoidCallback onTap;

  const TokenListItem({
    super.key,
    required this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Token logo
              _buildLogo(),
              const SizedBox(width: 12),

              // Token info (name, symbol, network)
              Expanded(child: _buildTokenInfo()),

              // Balance and value
              _buildBalanceInfo(),

              // Arrow icon for navigation
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: token.logo != null ? NetworkImage(token.logo!) : null,
          child: token.logo == null
              ? Text(
                  token.symbol.isNotEmpty ? token.symbol[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        // Native token badge
        if (token.isNative)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.star,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTokenInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                token.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildNetworkBadge(),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          token.name,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNetworkBadge() {
    final networkColor = NetworkUtils.getColor(token.network);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: networkColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        NetworkUtils.getDisplayName(token.network),
        style: TextStyle(
          fontSize: 10,
          color: networkColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          token.formattedBalance,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          token.formattedValueUsd,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

}

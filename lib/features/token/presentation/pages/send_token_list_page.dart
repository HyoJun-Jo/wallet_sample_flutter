import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/networks.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/token_info.dart';
import '../bloc/token_bloc.dart';
import '../bloc/token_event.dart';
import '../bloc/token_state.dart';

/// Send token list page - displays tokens available for sending
class SendTokenListPage extends StatefulWidget {
  final String walletAddress;

  const SendTokenListPage({
    super.key,
    required this.walletAddress,
  });

  @override
  State<SendTokenListPage> createState() => _SendTokenListPageState();
}

class _SendTokenListPageState extends State<SendTokenListPage> {
  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  void _loadTokens() {
    final chainRepository = sl<ChainRepository>();
    final networks = AppConstants.isDev
        ? chainRepository.testnetNetworks
        : chainRepository.mainnetNetworks;
    context.read<TokenBloc>().add(AllTokensRequested(
          walletAddress: widget.walletAddress,
          networks: networks,
        ));
  }

  void _onTokenTap(TokenInfo token) {
    context.push(
      '/transfer',
      extra: {
        'walletAddress': widget.walletAddress,
        'token': token,
      },
    );
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
      body: BlocConsumer<TokenBloc, TokenState>(
        listener: (context, state) {
          if (state is TokenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is TokenLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AllTokensLoaded && state.tokens.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.tokens.length,
              itemBuilder: (context, index) =>
                  _buildTokenItem(state.tokens[index]),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.token_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tokens available',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenItem(TokenInfo token) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _onTokenTap(token),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Token Icon with badge
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: token.logo != null && token.logo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            token.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildTokenInitial(token),
                          ),
                        )
                      : _buildTokenInitial(token),
                ),
                if (token.isNative)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        size: 10,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Token Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (!token.isNative) ...[
                        _buildNetworkBadge(token.network),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          '${token.formattedBalance} ${token.symbol}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  token.formattedValueUsd,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                _buildPriceChange(token),
              ],
            ),
            // Arrow
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInitial(TokenInfo token) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        token.symbol.isNotEmpty ? token.symbol[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNetworkBadge(String network) {
    final iconUrl = Networks.getIcon(network);
    if (iconUrl == null) return const SizedBox.shrink();

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        width: 16,
        height: 16,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(width: 16, height: 16),
        errorWidget: (context, url, error) =>
            const SizedBox(width: 16, height: 16),
      ),
    );
  }

  Widget _buildPriceChange(TokenInfo token) {
    final priceChange = token.priceChange1d ?? 0.0;
    final valueChange = token.valueUsd != null
        ? token.valueUsd! * (priceChange / 100)
        : 0.0;
    final isPositive = priceChange >= 0;

    return Text(
      '${isPositive ? '+' : ''}${FormatUtils.formatPercent(priceChange)} (${FormatUtils.formatUsd(valueChange.abs())})',
      style: TextStyle(
        fontSize: 14,
        color: isPositive ? Colors.green : Colors.red,
      ),
    );
  }
}

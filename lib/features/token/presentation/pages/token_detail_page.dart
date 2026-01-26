import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/network_utils.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/token_info.dart';
import '../widgets/mini_price_chart.dart';

/// Token detail page - SDK aligned layout
class TokenDetailPage extends StatefulWidget {
  final String walletAddress;
  final TokenInfo token;

  const TokenDetailPage({
    super.key,
    required this.walletAddress,
    required this.token,
  });

  @override
  State<TokenDetailPage> createState() => _TokenDetailPageState();
}

class _TokenDetailPageState extends State<TokenDetailPage> {
  bool _isAboutExpanded = false;
  bool _copiedAddress = false;

  TokenInfo get token => widget.token;
  String get walletAddress => widget.walletAddress;

  // Price change calculations using entity getters
  double? get priceChangePercent => token.priceChangePercent;
  double? get priceChange1d => token.priceChange1d;
  double? get priceChange1w => token.priceChange1w;
  double? get priceChange1m => token.priceChange1m;
  double? get marketCap => token.marketCap;
  double? get balanceValueKrw => token.valueKrw;

  bool get isPositiveChange => (priceChangePercent ?? 0) >= 0;
  bool get hasMarketInfo =>
      marketCap != null ||
      priceChange1d != null ||
      priceChange1w != null ||
      priceChange1m != null;

  @override
  Widget build(BuildContext context) {
    final chainRepository = sl<ChainRepository>();
    final chain = chainRepository.getByNetwork(token.network);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, chain),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Price Section
                    _buildPriceSection(context),
                    // My Balance Section
                    _buildBalanceSection(context),
                    // Action Buttons
                    _buildActionButtons(context),
                    // Transaction History Link
                    _buildHistoryLink(context),
                    // About Section
                    if (token.description != null && token.description!.isNotEmpty)
                      _buildAboutSection(context),
                    // Network Info
                    _buildNetworkSection(context, chain),
                    // Market Info
                    if (hasMarketInfo) _buildMarketInfoSection(context),
                    // Resources
                    _buildResourcesSection(context, chain),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic chain) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          // Token icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: token.logo != null && token.logo!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      token.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultIcon(16),
                    ),
                  )
                : _buildDefaultIcon(16),
          ),
          const SizedBox(width: 12),
          // Token name
          Expanded(
            child: Text(
              token.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultIcon(double fontSize) {
    return Center(
      child: Text(
        token.symbol.isNotEmpty ? token.symbol.substring(0, token.symbol.length.clamp(0, 2)).toUpperCase() : '?',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return _buildSection(
      title: 'Price',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FormatUtils.formatUsd(token.priceUsd),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (priceChangePercent != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${isPositiveChange ? '+' : ''}${priceChangePercent!.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPositiveChange ? const Color(0xFF00D1A7) : const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ],
            ),
            if (token.chartData != null && token.chartData!.length > 1)
              MiniPriceChart(
                data: token.chartData!,
                width: 100,
                height: 40,
                isPositive: isPositiveChange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context) {
    return _buildSection(
      title: 'My Balance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FormatUtils.formatKrw(balanceValueKrw),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${token.formattedBalance} ${token.symbol}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.call_received,
              label: 'Receive',
              onTap: () => _copyToClipboard(walletAddress, 'Address copied'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.call_made,
              label: 'Send',
              onTap: () => _onSendTap(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryLink(BuildContext context) {
    return _buildSection(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction history coming soon')),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final description = token.description!;
    final showToggle = description.length > 150;

    return _buildSection(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(fontSize: 14, height: 1.5),
            maxLines: _isAboutExpanded ? null : 4,
            overflow: _isAboutExpanded ? null : TextOverflow.ellipsis,
          ),
          if (showToggle) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isAboutExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isAboutExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkSection(BuildContext context, dynamic chain) {
    return _buildSection(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Network',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Row(
            children: [
              if (chain != null && chain.icon.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    chain.icon,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                chain?.name ?? NetworkUtils.formatDisplayName(token.network),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInfoSection(BuildContext context) {
    return _buildSection(
      title: 'Market Info',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (marketCap != null)
              _buildMarketInfoRow('Market Cap', FormatUtils.formatLargeNumber(marketCap!)),
            if (priceChange1d != null)
              _buildMarketInfoRow('1 Day', FormatUtils.formatPercent(priceChange1d!, showSign: true, asRaw: true), priceChange1d! >= 0),
            if (priceChange1w != null)
              _buildMarketInfoRow('1 Week', FormatUtils.formatPercent(priceChange1w!, showSign: true, asRaw: true), priceChange1w! >= 0),
            if (priceChange1m != null)
              _buildMarketInfoRow('1 Month', FormatUtils.formatPercent(priceChange1m!, showSign: true, asRaw: true), priceChange1m! >= 0),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketInfoRow(String label, String value, [bool? isPositive]) {
    Color? valueColor;
    if (isPositive != null) {
      valueColor = isPositive ? const Color(0xFF00D1A7) : const Color(0xFFFF6B6B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(BuildContext context, dynamic chain) {
    return _buildSection(
      title: 'Resources',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Contract Address (for non-native tokens)
            if (!token.isNative && token.contractAddress != null && token.contractAddress!.isNotEmpty)
              _buildResourceItem(
                label: 'Contract Address',
                value: AddressUtils.shorten(token.contractAddress!, prefixLength: 8, suffixLength: 6),
                onCopy: () => _copyToClipboard(token.contractAddress!, 'Contract address copied'),
                onOpenExplorer: chain?.explorerDetailUrl != null
                    ? () => _openUrl('${chain!.explorerDetailUrl}${token.contractAddress}')
                    : null,
              ),
            // CoinGecko
            _buildResourceItem(
              label: 'CoinGecko',
              onTap: () => _openUrl('https://www.coingecko.com/en/coins/${token.symbol.toLowerCase()}'),
            ),
            // Website
            if (token.website != null && token.website!.isNotEmpty)
              _buildResourceItem(
                label: 'Official Website',
                onTap: () => _openUrl(token.website!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem({
    required String label,
    String? value,
    VoidCallback? onTap,
    VoidCallback? onCopy,
    VoidCallback? onOpenExplorer,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const Spacer(),
            if (onCopy != null)
              IconButton(
                icon: Icon(
                  _copiedAddress ? Icons.check : Icons.copy,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                onPressed: () {
                  onCopy();
                  setState(() => _copiedAddress = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copiedAddress = false);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (onOpenExplorer != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade500),
                onPressed: onOpenExplorer,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
            if (onTap != null && onCopy == null && onOpenExplorer == null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  void _onSendTap(BuildContext context) {
    context.push(
      '/transfer',
      extra: {
        'walletAddress': walletAddress,
        'token': token,
      },
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

}

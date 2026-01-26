import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/chain/chain_repository.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../history/presentation/widgets/history_list.dart';
import '../../domain/entities/token_info.dart' show TokenInfo, getPriceChange1d;
import '../bloc/token_bloc.dart';
import '../bloc/token_event.dart';
import '../bloc/token_state.dart';

class TokenTabPage extends StatefulWidget {
  final String walletAddress;

  const TokenTabPage({
    super.key,
    required this.walletAddress,
  });

  @override
  State<TokenTabPage> createState() => _TokenTabPageState();
}

class _TokenTabPageState extends State<TokenTabPage> {
  int _selectedTabIndex = 0;
  String _selectedNetwork = 'All Networks';

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  void _loadTokens() {
    final chainRepository = sl<ChainRepository>();
    final networks = kDebugMode
        ? chainRepository.allNetworks
        : chainRepository.mainnetNetworks;
    context.read<TokenBloc>().add(AllTokensRequested(
          walletAddress: widget.walletAddress,
          networks: networks,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header (fixed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHeader(),
            ),
            // Scrollable content
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildTokensScrollView()
                  : BlocProvider(
                      create: (context) => sl<HistoryBloc>(),
                      child: _HistoryContent(
                        walletAddress: widget.walletAddress,
                        balanceSection: _buildBalanceSection(),
                        tabBar: _buildTabBar(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokensScrollView() {
    return BlocConsumer<TokenBloc, TokenState>(
      listener: (context, state) {
        if (state is TokenError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            // Balance + Action Grid
            SliverToBoxAdapter(child: _buildBalanceSection()),
            // Tab Bar
            SliverToBoxAdapter(child: _buildTabBar()),
            // Content
            if (state is TokenLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is AllTokensLoaded && state.tokens.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTokenItem(state.tokens[index]),
                    childCount: state.tokens.length,
                  ),
                ),
              )
            else
              SliverFillRemaining(child: _buildEmptyState()),
          ],
        );
      },
    );
  }

  Widget _buildBalanceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalBalance(),
          const SizedBox(height: 16),
          _buildActionGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.person, size: 16, color: colorScheme.onPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '@${AddressUtils.shorten(widget.walletAddress)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
        // Action Icons
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
              onPressed: () {
                // TODO: QR Scanner
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.settings, color: colorScheme.primary),
              onPressed: () {
                // TODO: Settings
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.download, color: colorScheme.primary),
              onPressed: _onReceiveTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalBalance() {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<TokenBloc, TokenState>(
      builder: (context, state) {
        String totalBalance = '₩0';
        if (state is AllTokensLoaded) {
          totalBalance = FormatUtils.formatKrw(state.totalValueKrw);
        }
        return Text(
          totalBalance,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  Widget _buildActionGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.arrow_upward,
            label: 'Send',
            onTap: _onSendTap,
          ),
          _buildActionButton(
            icon: Icons.arrow_downward,
            label: 'Receive',
            onTap: _onReceiveTap,
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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tabs
          Row(
            children: [
              _buildTabItem('Tokens', 0),
              const SizedBox(width: 4),
              _buildTabItem('History', 1),
            ],
          ),
          // Network Dropdown
          _buildNetworkDropdown(),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkDropdown() {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _showNetworkPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'All Networks',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _showNetworkPicker() {
    final chainRepository = sl<ChainRepository>();
    final networkList = chainRepository.allNetworks.split(',');
    final networks = ['All Networks', ...networkList];
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: networks.length,
        itemBuilder: (context, index) {
          final network = networks[index];
          return ListTile(
            title: Text(network),
            trailing: _selectedNetwork == network
                ? Icon(Icons.check, color: colorScheme.primary)
                : null,
            onTap: () {
              setState(() => _selectedNetwork = network);
              Navigator.pop(context);
              _loadTokens();
            },
          );
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
            'No Tokens',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tokens will appear here when received',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadTokens,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
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
                            errorBuilder: (_, __, ___) => _buildTokenInitial(token),
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
                  Text(
                    '${token.formattedBalance} ${token.symbol}',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Value and Change
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

  Widget _buildPriceChange(TokenInfo token) {
    final priceChange = getPriceChange1d(token.chartData) ?? 0.0;
    final valueChange = token.valueUsd != null
        ? token.valueUsd! * (priceChange / 100)
        : 0.0;
    final isPositive = priceChange >= 0;

    return Text(
      '${isPositive ? '+' : ''}${FormatUtils.formatPercent(priceChange)} (${FormatUtils.formatUsd(valueChange.abs())})',
      style: TextStyle(
        fontSize: 16,
        color: isPositive ? Colors.green : Colors.red,
      ),
    );
  }

  void _onTokenTap(TokenInfo token) {
    context.push(
      '/token/detail',
      extra: {
        'walletAddress': widget.walletAddress,
        'token': token,
      },
    );
  }

  void _onSendTap() {
    context.push(
      '/transfer',
      extra: {
        'walletAddress': widget.walletAddress,
      },
    );
  }

  void _onReceiveTap() {
    // TODO: Navigate to receive page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receive feature coming soon')),
    );
  }
}

class _HistoryContent extends StatefulWidget {
  final String walletAddress;
  final Widget balanceSection;
  final Widget tabBar;

  const _HistoryContent({
    required this.walletAddress,
    required this.balanceSection,
    required this.tabBar,
  });

  @override
  State<_HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<_HistoryContent> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final chainRepository = sl<ChainRepository>();
    final networks = kDebugMode
        ? chainRepository.allNetworks
        : chainRepository.mainnetNetworks;

    context.read<HistoryBloc>().add(HistoryRequested(
          walletAddress: widget.walletAddress,
          networks: networks,
          isNft: false,
          forceRefresh: true,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HistoryBloc, HistoryState>(
      listener: (context, state) {
        if (state is HistoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: widget.balanceSection),
            SliverToBoxAdapter(child: widget.tabBar),
            if (state is HistoryLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is HistoryLoaded)
              SliverToBoxAdapter(
                child: HistoryList(
                  entries: state.entries,
                  onRefresh: _loadHistory,
                ),
              )
            else
              SliverToBoxAdapter(
                child: HistoryList(
                  entries: const [],
                  onRefresh: _loadHistory,
                ),
              ),
          ],
        );
      },
    );
  }
}

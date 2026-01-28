import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/chain/chain_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/networks.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../../shared/wallet/domain/entities/wallet_credentials.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/presentation/widgets/history_list.dart';
import '../../domain/entities/token_info.dart';
import '../bloc/token_bloc.dart';
import '../bloc/token_event.dart';
import '../bloc/token_state.dart';

class TokenTabPage extends StatefulWidget {
  final String walletAddress;
  final WalletCredentials? credentials;

  const TokenTabPage({
    super.key,
    required this.walletAddress,
    this.credentials,
  });

  @override
  State<TokenTabPage> createState() => _TokenTabPageState();
}

class _TokenTabPageState extends State<TokenTabPage> {
  int _selectedTabIndex = 0;
  String _selectedNetwork = 'all'; // 'all' means "All Networks"

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
                  : BlocBuilder<TokenBloc, TokenState>(
                      builder: (context, tokenState) {
                        final tokens = tokenState is AllTokensLoaded
                            ? tokenState.tokens
                            : <TokenInfo>[];
                        return BlocProvider(
                          create: (context) => sl<HistoryBloc>(),
                          child: _HistoryContent(
                            walletAddress: widget.walletAddress,
                            tokens: tokens,
                            selectedNetwork: _selectedNetwork,
                            balanceSection: _buildBalanceSection(),
                            tabBar: _buildTabBar(),
                          ),
                        );
                      },
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
        // Filter tokens by selected network and exclude spam
        final allTokens = state is AllTokensLoaded
            ? state.tokens.where((t) => !t.possibleSpam).toList()
            : <TokenInfo>[];
        final filteredTokens = _selectedNetwork == 'all'
            ? allTokens
            : allTokens.where((t) => t.network == _selectedNetwork).toList();

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
            else if (filteredTokens.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTokenItem(filteredTokens[index]),
                    childCount: filteredTokens.length,
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
        IconButton(
          icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
          onPressed: () {
            // TODO: QR Scanner
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
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
    final chainRepository = sl<ChainRepository>();
    final networks = AppConstants.isDev
        ? chainRepository.testnetNetworks
        : chainRepository.mainnetNetworks;
    final networkList = networks.split(',');

    // Get tokens for calculating network values (exclude spam)
    final tokenState = context.read<TokenBloc>().state;
    final tokens = tokenState is AllTokensLoaded
        ? tokenState.tokens.where((t) => !t.possibleSpam).toList()
        : <TokenInfo>[];

    return PopupMenuButton<String>(
      onSelected: (network) {
        setState(() => _selectedNetwork = network);
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
      itemBuilder: (context) => [
        // All Networks option
        _buildNetworkMenuItem(
          network: 'all',
          tokens: tokens,
          colorScheme: colorScheme,
        ),
        const PopupMenuDivider(height: 1),
        // Individual network options
        ...networkList.map((network) => _buildNetworkMenuItem(
              network: network,
              tokens: tokens,
              colorScheme: colorScheme,
            )),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedNetwork != 'all'
                ? Networks.getConfig(_selectedNetwork)?.name ??
                    _selectedNetwork
                : 'All Networks',
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

  PopupMenuEntry<String> _buildNetworkMenuItem({
    required String network,
    required List<TokenInfo> tokens,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedNetwork == network;
    final networkTokens = network == 'all'
        ? tokens
        : tokens.where((t) => t.network == network).toList();
    final totalValue = networkTokens.fold<double>(
      0,
      (sum, t) => sum + (t.valueUsd ?? 0),
    );

    return PopupMenuItem<String>(
      value: network,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Network icon
          _buildNetworkIcon(network, colorScheme),
          const SizedBox(width: 12),
          // Network name & value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  network != 'all'
                      ? Networks.getConfig(network)?.name ?? network
                      : 'All Networks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  FormatUtils.formatUsd(totalValue),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Radio indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkIcon(String network, ColorScheme colorScheme) {
    if (network == 'all') {
      // All Networks icon
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '∞',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    final iconUrl = Networks.getIcon(network);
    if (iconUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: iconUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildPlaceholderIcon(network, colorScheme),
          errorWidget: (_, __, ___) =>
              _buildPlaceholderIcon(network, colorScheme),
        ),
      );
    }

    return _buildPlaceholderIcon(network, colorScheme);
  }

  Widget _buildPlaceholderIcon(String network, ColorScheme colorScheme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          network.substring(0, 2).toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
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
                            fontSize: 16,
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
        errorWidget: (context, url, error) => const SizedBox(width: 16, height: 16),
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
      '/send',
      extra: {
        'walletAddress': widget.walletAddress,
      },
    );
  }

  void _onReceiveTap() {
    debugPrint('[TokenTabPage] _onReceiveTap - credentials: ${widget.credentials}');
    final credentials = widget.credentials;
    if (credentials != null) {
      context.push('/address', extra: credentials);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지갑 정보를 불러올 수 없습니다')),
      );
    }
  }
}

class _HistoryContent extends StatefulWidget {
  final String walletAddress;
  final List<TokenInfo> tokens;
  final String selectedNetwork;
  final Widget balanceSection;
  final Widget tabBar;

  const _HistoryContent({
    required this.walletAddress,
    required this.tokens,
    required this.selectedNetwork,
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
    final networks = AppConstants.isDev
        ? chainRepository.testnetNetworks
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
        // Filter entries by selected network
        final allEntries =
            state is HistoryLoaded ? state.entries : <HistoryEntry>[];
        final filteredEntries = widget.selectedNetwork == 'all'
            ? allEntries
            : allEntries
                .where((e) => e.network == widget.selectedNetwork)
                .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: widget.balanceSection),
            SliverToBoxAdapter(child: widget.tabBar),
            if (state is HistoryLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              HistoryList(
                entries: filteredEntries,
                walletAddress: widget.walletAddress,
                tokens: widget.tokens,
                onRefresh: _loadHistory,
                asSliver: true,
              ),
          ],
        );
      },
    );
  }
}

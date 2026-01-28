import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../token/domain/entities/token_info.dart';
import '../../domain/entities/history_entry.dart';
import 'history_item.dart';

class HistoryList extends StatelessWidget {
  final List<HistoryEntry> entries;
  final String walletAddress;
  final List<TokenInfo>? tokens;
  final VoidCallback? onRefresh;
  final void Function(HistoryEntry)? onEntryTap;
  final bool asSliver;
  final bool showDateHeaders;

  const HistoryList({
    super.key,
    required this.entries,
    this.walletAddress = '',
    this.tokens,
    this.onRefresh,
    this.onEntryTap,
    this.asSliver = false,
    this.showDateHeaders = true,
  });

  /// Find token logo by contract address and network
  String? _findTokenLogo(HistoryEntry entry) {
    if (tokens == null || tokens!.isEmpty) return null;

    // For native coin transfers, find by network and isNative
    if (entry.type == HistoryType.coinTransfer) {
      final token = tokens!.cast<TokenInfo?>().firstWhere(
            (t) => t!.network == entry.network && t.isNative,
            orElse: () => null,
          );
      return token?.logo;
    }

    // For token/NFT transfers, find by contract address
    if (entry.contractAddress != null && entry.contractAddress!.isNotEmpty) {
      final token = tokens!.cast<TokenInfo?>().firstWhere(
            (t) =>
                t!.network == entry.network &&
                t.contractAddress?.toLowerCase() ==
                    entry.contractAddress!.toLowerCase(),
            orElse: () => null,
          );
      return token?.logo;
    }

    return null;
  }

  /// Group entries by date
  Map<String, List<HistoryEntry>> _groupByDate() {
    final Map<String, List<HistoryEntry>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in entries) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );

      String dateKey;
      if (entryDate == today) {
        dateKey = 'Today';
      } else if (entryDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat('MMM d, yyyy').format(entry.timestamp);
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(entry);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (asSliver) {
      return _buildSliverContent(context);
    }

    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildHistoryList(context);
  }

  Widget _buildSliverContent(BuildContext context) {
    if (entries.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }

    final colorScheme = Theme.of(context).colorScheme;

    if (!showDateHeaders) {
      // Flat list without date grouping
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: entries.asMap().entries.map((e) {
                final index = e.key;
                final entry = e.value;
                return Column(
                  children: [
                    HistoryItem(
                      entry: entry,
                      walletAddress: walletAddress,
                      tokenLogo: _findTokenLogo(entry),
                      onTap: () => onEntryTap?.call(entry),
                    ),
                    if (index < entries.length - 1)
                      Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    // Grouped by date
    final groupedEntries = _groupByDate();
    final dateKeys = groupedEntries.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final dateKey = dateKeys[index];
            final dateEntries = groupedEntries[dateKey]!;

            return _buildDateGroup(context, dateKey, dateEntries);
          },
          childCount: dateKeys.length,
        ),
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    String dateKey,
    List<HistoryEntry> dateEntries,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              dateKey,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Transactions Container
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: dateEntries.asMap().entries.map((e) {
                final index = e.key;
                final entry = e.value;
                return Column(
                  children: [
                    HistoryItem(
                      entry: entry,
                      walletAddress: walletAddress,
                      tokenLogo: _findTokenLogo(entry),
                      onTap: () => onEntryTap?.call(entry),
                    ),
                    if (index < dateEntries.length - 1)
                      Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📜',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No transaction history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: showDateHeaders
          ? _buildGroupedList(context, colorScheme)
          : _buildFlatList(context, colorScheme),
    );
  }

  Widget _buildGroupedList(BuildContext context, ColorScheme colorScheme) {
    final groupedEntries = _groupByDate();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final dateKey = groupedEntries.keys.elementAt(index);
        final dateEntries = groupedEntries[dateKey]!;

        return _buildDateGroup(context, dateKey, dateEntries);
      },
    );
  }

  Widget _buildFlatList(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: entries.asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              return Column(
                children: [
                  HistoryItem(
                    entry: entry,
                    walletAddress: walletAddress,
                    tokenLogo: _findTokenLogo(entry),
                    onTap: () => onEntryTap?.call(entry),
                  ),
                  if (index < entries.length - 1)
                    Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

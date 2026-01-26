import 'package:flutter/material.dart';

import '../../domain/entities/history_entry.dart';
import 'history_item.dart';

class HistoryList extends StatelessWidget {
  final List<HistoryEntry> entries;
  final VoidCallback? onRefresh;
  final void Function(HistoryEntry)? onEntryTap;

  const HistoryList({
    super.key,
    required this.entries,
    this.onRefresh,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildHistoryList(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No History',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'History will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
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
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${entries.length} entries',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  return HistoryItem(
                    entry: entry,
                    onTap: () => onEntryTap?.call(entry),
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }
}

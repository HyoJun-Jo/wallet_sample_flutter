import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/networks.dart';
import '../../../../core/utils/address_utils.dart';
import '../pages/address_detail_page.dart';

class AddressRow extends StatelessWidget {
  final String chainName;
  final String network;
  final String address;
  final List<NetworkConfig>? subNetworks;

  const AddressRow({
    super.key,
    required this.chainName,
    required this.network,
    required this.address,
    this.subNetworks,
  });

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$chainName address copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showQrPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressDetailPage(
          chainName: chainName,
          network: network,
          address: address,
          subNetworks: subNetworks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconUrl = Networks.getIcon(network);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Row: Icon + Name/Address + Buttons
          Row(
            children: [
              // Chain Icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: iconUrl != null
                      ? CachedNetworkImage(
                          imageUrl: iconUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.currency_exchange,
                            size: 18,
                            color: colorScheme.onSurface,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.currency_exchange,
                            size: 18,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : Icon(
                          Icons.currency_exchange,
                          size: 18,
                          color: colorScheme.onSurface,
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Chain Name and Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$chainName address',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AddressUtils.shorten(address),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _showQrPage(context),
                  icon: Icon(
                    Icons.qr_code_2,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _copyAddress(context),
                  icon: Icon(
                    Icons.copy,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          // Network List (for Ethereum)
          if (subNetworks != null && subNetworks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...subNetworks!.map((config) => _buildNetworkItem(context, config)),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkItem(BuildContext context, NetworkConfig config) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: config.icon,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  Icons.circle,
                  size: 12,
                  color: colorScheme.onSurface,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.circle,
                  size: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            config.name,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

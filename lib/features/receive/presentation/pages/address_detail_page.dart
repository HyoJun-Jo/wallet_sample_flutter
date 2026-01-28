import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/networks.dart';

class AddressDetailPage extends StatelessWidget {
  final String chainName;
  final String network;
  final String address;
  final List<NetworkConfig>? subNetworks;

  const AddressDetailPage({
    super.key,
    required this.chainName,
    required this.network,
    required this.address,
    this.subNetworks,
  });

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareAddress() {
    Share.share(address, subject: '$chainName Address');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconUrl = Networks.getIcon(network);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Chain Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: iconUrl != null
                            ? CachedNetworkImage(
                                imageUrl: iconUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Icon(
                                  Icons.currency_exchange,
                                  size: 24,
                                  color: colorScheme.onSurface,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.currency_exchange,
                                  size: 24,
                                  color: colorScheme.onSurface,
                                ),
                              )
                            : Icon(
                                Icons.currency_exchange,
                                size: 24,
                                color: colorScheme.onSurface,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Chain Name
                    Text(
                      '$chainName address',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    // Sub Networks Row (for Ethereum)
                    if (subNetworks != null && subNetworks!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: subNetworks!
                            .map((config) => _buildNetworkIcon(config))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: address,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Address with copy icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _copyAddress(context),
                          child: Icon(
                            Icons.copy,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Copy Address Button
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _copyAddress(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Address'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share Button
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _shareAddress,
                      icon: Icon(
                        Icons.ios_share,
                        color: colorScheme.onPrimary,
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkIcon(NetworkConfig config) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: config.icon,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(),
            errorWidget: (context, url, error) => const SizedBox(),
          ),
        ),
      ),
    );
  }
}

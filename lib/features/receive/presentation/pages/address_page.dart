import 'package:flutter/material.dart';
import '../../../../core/constants/networks.dart';
import '../../../../shared/wallet/domain/entities/wallet_credentials.dart';
import '../widgets/address_row.dart';

class AddressPage extends StatelessWidget {
  final WalletCredentials credentials;

  const AddressPage({
    super.key,
    required this.credentials,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bitcoin Address
              if (credentials.btcAddress != null &&
                  credentials.btcAddress!.isNotEmpty)
                AddressRow(
                  chainName: 'Bitcoin',
                  network: 'bitcoin',
                  address: credentials.btcAddress!,
                ),

              // Ethereum Address (EVM)
              AddressRow(
                chainName: 'Ethereum',
                network: 'ethereum',
                address: credentials.address,
                subNetworks: [
                  Networks.configs['arbitrum']!,
                  Networks.configs['avalanche']!,
                  Networks.configs['binance']!,
                  Networks.configs['kaia']!,
                  Networks.configs['polygon']!,
                ],
              ),

              // Solana Address
              if (credentials.solAddress != null &&
                  credentials.solAddress!.isNotEmpty)
                AddressRow(
                  chainName: 'Solana',
                  network: 'solana',
                  address: credentials.solAddress!,
                ),

              const SizedBox(height: 16),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure to send tokens on the correct network. Sending tokens on the wrong network may result in permanent loss.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

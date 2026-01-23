import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/injection_container.dart';
import '../../../browser/presentation/bloc/browser_bloc.dart';
import '../../../browser/presentation/pages/web3_browser_page.dart';
import '../../../token/presentation/bloc/token_bloc.dart';
import '../../../token/presentation/pages/token_list_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../core/wallet/repositories/wallet_repository.dart';

class MainTabPage extends StatefulWidget {
  final String? walletAddress;

  const MainTabPage({
    super.key,
    this.walletAddress,
  });

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;
  String _walletAddress = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _walletAddress = widget.walletAddress ?? '';
    _loadWalletAddress();
  }

  Future<void> _loadWalletAddress() async {
    if (_walletAddress.isEmpty) {
      // Load wallet address from storage if not provided
      final walletRepository = sl<WalletRepository>();
      try {
        final result = await walletRepository.getSavedWallets();
        result.fold(
          (failure) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          (wallets) {
            if (mounted) {
              setState(() {
                if (wallets.isNotEmpty) {
                  _walletAddress = wallets.first.address;
                }
                _isLoading = false;
              });
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while fetching wallet address
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if no wallet address
    if (_walletAddress.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No wallet found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWalletAddress,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Token Tab
          BlocProvider(
            create: (_) => sl<TokenBloc>(),
            child: TokenListPage(walletAddress: _walletAddress),
          ),
          // Browser Tab
          BlocProvider(
            create: (_) => sl<BrowserBloc>(),
            child: Web3BrowserPage(walletAddress: _walletAddress),
          ),
          // Settings Tab
          BlocProvider(
            create: (_) => sl<SettingsBloc>()
              ..add(const SettingsLoadRequested()),
            child: const SettingsPage(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Tokens',
          ),
          NavigationDestination(
            icon: Icon(Icons.language_outlined),
            selectedIcon: Icon(Icons.language),
            label: 'Browser',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

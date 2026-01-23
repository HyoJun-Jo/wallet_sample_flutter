import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/wallet/repositories/wallet_repository.dart';
import '../../di/injection_container.dart';
import '../../features/browser/presentation/bloc/browser_bloc.dart';
import '../../features/browser/presentation/pages/web3_browser_page.dart';
import '../../features/token/presentation/bloc/token_bloc.dart';
import '../../features/token/presentation/pages/token_list_page.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/bloc/settings_event.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

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
  String? _walletAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWalletAddress();
  }

  Future<void> _initWalletAddress() async {
    if (widget.walletAddress != null) {
      setState(() {
        _walletAddress = widget.walletAddress;
        _isLoading = false;
      });
      return;
    }

    // Fetch from repository if not provided
    final result = await sl<WalletRepository>().getSavedWallets();
    result.fold(
      (failure) {
        setState(() => _isLoading = false);
      },
      (wallets) {
        setState(() {
          _walletAddress = wallets.isNotEmpty ? wallets.first.address : null;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final walletAddress = _walletAddress ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Token Tab
          BlocProvider(
            create: (_) => sl<TokenBloc>(),
            child: TokenListPage(walletAddress: walletAddress),
          ),
          // Browser Tab
          BlocProvider(
            create: (_) => sl<BrowserBloc>(),
            child: Web3BrowserPage(walletAddress: walletAddress),
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

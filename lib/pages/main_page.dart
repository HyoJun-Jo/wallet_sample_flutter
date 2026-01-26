import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../shared/wallet/domain/repositories/wallet_repository.dart';
import '../di/injection_container.dart';
import '../features/browser/presentation/bloc/browser_bloc.dart';
import '../features/browser/presentation/pages/web3_browser_tab_page.dart';
import '../features/token/presentation/bloc/token_bloc.dart';
import '../features/token/presentation/pages/token_tab_page.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../features/settings/presentation/bloc/settings_event.dart';
import '../features/settings/presentation/pages/settings_tab_page.dart';

class MainPage extends StatefulWidget {
  final String? walletAddress;

  const MainPage({
    super.key,
    this.walletAddress,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
    final result = await sl<WalletRepository>().getWalletCredentials();
    result.fold(
      (failure) {
        setState(() => _isLoading = false);
      },
      (credentials) {
        setState(() {
          _walletAddress = credentials?.address;
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
            child: TokenTabPage(walletAddress: walletAddress),
          ),
          // Browser Tab
          BlocProvider(
            create: (_) => sl<BrowserBloc>(),
            child: Web3BrowserTabPage(walletAddress: walletAddress),
          ),
          // Settings Tab
          BlocProvider(
            create: (_) => sl<SettingsBloc>()
              ..add(const SettingsLoadRequested()),
            child: const SettingsTabPage(),
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

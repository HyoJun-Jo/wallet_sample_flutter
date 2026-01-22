import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/session/session_manager.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../di/injection_container.dart';
import '../../../auth/domain/entities/auth_entities.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _userEmail = '';
  LoginType _loginType = LoginType.email;
  String _walletAddress = '';
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final localStorage = sl<LocalStorageService>();
    final walletRepository = sl<WalletRepository>();
    final packageInfo = await PackageInfo.fromPlatform();

    // Get wallet address from saved wallets
    String walletAddress = '';
    final walletsResult = await walletRepository.getSavedWallets();
    walletsResult.fold(
      (failure) {},
      (wallets) {
        if (wallets.isNotEmpty) {
          walletAddress = wallets.first.address;
        }
      },
    );

    if (mounted) {
      setState(() {
        _userEmail = localStorage.getString(LocalStorageKeys.userEmail) ?? '';
        final loginTypeStr = localStorage.getString(LocalStorageKeys.loginType);
        _loginType = LoginType.values.firstWhere(
          (e) => e.name == loginTypeStr,
          orElse: () => LoginType.email,
        );
        _walletAddress = walletAddress;
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sl<SessionManager>().logout();
    }
  }

  void _copyAddress() {
    if (_walletAddress.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _walletAddress));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _shortenAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _getLoginTypeIcon(LoginType type) {
    switch (type) {
      case LoginType.google:
        return 'G';
      case LoginType.apple:
        return '';
      case LoginType.kakao:
        return 'K';
      case LoginType.email:
      default:
        return '@';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Profile Section
                _buildSectionHeader('Profile'),
                _buildTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: _userEmail.isNotEmpty ? _userEmail : 'Not logged in',
                ),
                _buildTile(
                  icon: Icons.login,
                  title: 'Login Type',
                  subtitle: _loginType.name.toUpperCase(),
                  trailing: CircleAvatar(
                    radius: 14,
                    child: Text(
                      _getLoginTypeIcon(_loginType),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),

                const Divider(),

                // Wallet Section
                _buildSectionHeader('Wallet'),
                _buildTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Wallet Address',
                  subtitle: _walletAddress.isNotEmpty
                      ? _shortenAddress(_walletAddress)
                      : 'No wallet',
                  trailing: _walletAddress.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyAddress,
                        )
                      : null,
                  onTap: _walletAddress.isNotEmpty ? _copyAddress : null,
                ),

                const Divider(),

                // App Section
                _buildSectionHeader('App'),
                _buildTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: _appVersion,
                ),

                const SizedBox(height: 24),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Logout'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

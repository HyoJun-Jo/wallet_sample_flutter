import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/entities/auth_entities.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsLogoutInProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsLoaded) {
            return _SettingsContent(
              email: state.userSettings.email,
              loginType: state.userSettings.loginType,
              walletAddress: state.userSettings.walletAddress,
              appVersion: state.userSettings.appVersion,
            );
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<SettingsBloc>()
                          .add(const SettingsLoadRequested());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final String email;
  final LoginType loginType;
  final String? walletAddress;
  final String appVersion;

  const _SettingsContent({
    required this.email,
    required this.loginType,
    required this.walletAddress,
    required this.appVersion,
  });

  void _copyAddress(BuildContext context) {
    if (walletAddress != null && walletAddress!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: walletAddress!));
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

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(const SettingsLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Profile Section
        _buildSectionHeader(context, 'Profile'),
        _buildTile(
          icon: Icons.email,
          title: 'Email',
          subtitle: email.isNotEmpty ? email : 'Not logged in',
        ),
        _buildTile(
          icon: Icons.login,
          title: 'Login Type',
          subtitle: loginType.name.toUpperCase(),
          trailing: CircleAvatar(
            radius: 14,
            child: Text(
              _getLoginTypeIcon(loginType),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),

        const Divider(),

        // Wallet Section
        _buildSectionHeader(context, 'Wallet'),
        _buildTile(
          icon: Icons.account_balance_wallet,
          title: 'Wallet Address',
          subtitle: walletAddress != null && walletAddress!.isNotEmpty
              ? _shortenAddress(walletAddress!)
              : 'No wallet',
          trailing: walletAddress != null && walletAddress!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyAddress(context),
                )
              : null,
          onTap: walletAddress != null && walletAddress!.isNotEmpty
              ? () => _copyAddress(context)
              : null,
        ),

        const Divider(),

        // App Section
        _buildSectionHeader(context, 'App'),
        _buildTile(
          icon: Icons.info_outline,
          title: 'Version',
          subtitle: appVersion,
        ),

        const SizedBox(height: 24),

        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

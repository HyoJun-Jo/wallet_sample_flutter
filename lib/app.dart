import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/session/session_manager.dart';
import 'di/injection_container.dart';
import 'routes/app_router.dart';

class WalletSampleApp extends StatefulWidget {
  const WalletSampleApp({super.key});

  @override
  State<WalletSampleApp> createState() => _WalletSampleAppState();
}

class _WalletSampleAppState extends State<WalletSampleApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(sl<SessionManager>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wallet Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

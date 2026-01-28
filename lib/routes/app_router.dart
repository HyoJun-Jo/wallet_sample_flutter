import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_manager.dart';
import '../di/injection_container.dart';
import '../core/auth/entities/auth_entities.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/bloc/email_registration_bloc.dart';
import '../features/auth/presentation/bloc/sns_registration_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/email_registration_page.dart';
import '../features/auth/presentation/pages/password_reset_page.dart';
import '../features/auth/presentation/pages/sns_registration_page.dart';
import '../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../features/wallet/presentation/pages/create_wallet_page.dart';
import '../pages/main_page.dart';
import '../features/token/domain/entities/token_info.dart';
import '../features/token/presentation/pages/token_detail_page.dart';
import '../features/token/presentation/pages/send_token_list_page.dart';
import '../features/token/domain/entities/token_transfer.dart';
import '../features/token/presentation/bloc/token_transfer_bloc.dart';
import '../features/token/presentation/bloc/token_bloc.dart';
import '../features/token/presentation/pages/token_transfer_input_page.dart';
import '../features/token/presentation/pages/token_transfer_confirm_page.dart';
import '../features/token/presentation/pages/token_transfer_complete_page.dart';
import '../features/receive/presentation/pages/address_page.dart';
import '../shared/wallet/domain/entities/wallet_credentials.dart';
import '../pages/splash_page.dart';

// Route observer for tracking navigation
final routeObserver = RouteObserver<ModalRoute<dynamic>>();

// Auth-protected routes (redirect to login when session expires)
const _authProtectedPaths = ['/main', '/wallet', '/token', '/send', '/transfer'];

bool _isAuthProtectedPath(String path) {
  return _authProtectedPaths.any((p) => path.startsWith(p));
}

GoRouter createAppRouter(SessionManager sessionManager) => GoRouter(
  initialLocation: '/',
  observers: [routeObserver],
  refreshListenable: sessionManager,
  redirect: (context, state) {
    final currentPath = state.matchedLocation;
    final isOnSplash = currentPath == '/';
    final isOnLogin = currentPath == '/login';
    final isInitialized = sessionManager.isInitialized;
    final isAuthenticated = sessionManager.status == AuthStatus.authenticated;

    // Stay on splash until initialized
    if (!isInitialized) {
      return isOnSplash ? null : '/';
    }

    // After initialization, redirect from splash to appropriate route
    if (isOnSplash) {
      switch (sessionManager.initialRoute) {
        case InitialRoute.login:
          return '/login';
        case InitialRoute.walletCreate:
          return '/wallet/create';
        case InitialRoute.main:
          return '/main';
        case null:
          return '/login';
      }
    }

    // Authenticated users shouldn't be on login page
    // Navigation after login is handled by LoginPage
    if (isOnLogin && isAuthenticated) {
      return null; // Let LoginPage handle the navigation
    }

    // Redirect to login if session expired on protected routes
    final isAuthProtected = _isAuthProtectedPath(currentPath);
    if (!isAuthenticated && isAuthProtected) {
      return '/login';
    }

    return null;
  },
  routes: [
    // Splash screen (app entry point)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),

    // Login page
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<LoginBloc>(),
        child: const LoginPage(),
      ),
    ),

    // Email registration page (multi-step)
    GoRoute(
      path: '/register/email',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<EmailRegistrationBloc>(),
        child: const EmailRegistrationPage(),
      ),
    ),

    // Password reset page
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const PasswordResetPage(),
    ),

    // SNS registration page
    GoRoute(
      path: '/register/sns',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<SnsRegistrationBloc>(),
          child: SnsRegistrationPage(
            email: extra['email'] as String,
            sixcode: extra['sixcode'] as String,
            loginType: extra['loginType'] as LoginType,
            timeout: extra['timeout'] as int,
          ),
        );
      },
    ),

    // Wallet creation page
    GoRoute(
      path: '/wallet/create',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<WalletBloc>(),
        child: const CreateWalletPage(),
      ),
    ),

    // Main page (token, browser, settings tabs)
    GoRoute(
      path: '/main',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MainPage(
          walletAddress: extra?['walletAddress'] as String?,
        );
      },
    ),

    // Token detail page
    GoRoute(
      path: '/token/detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TokenDetailPage(
          walletAddress: extra['walletAddress'] as String,
          token: extra['token'] as TokenInfo,
        );
      },
    ),

    // Send token list page
    GoRoute(
      path: '/send',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<TokenBloc>(),
          child: SendTokenListPage(
            walletAddress: extra['walletAddress'] as String,
          ),
        );
      },
    ),

    // Token transfer input page
    GoRoute(
      path: '/transfer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BlocProvider(
          create: (_) => sl<TokenTransferBloc>(),
          child: TokenTransferInputPage(
            walletAddress: extra?['walletAddress'] ?? '',
            token: extra?['token'] as TokenInfo?,
          ),
        );
      },
    ),

    // Transfer confirm page
    GoRoute(
      path: '/transfer/confirm',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<TokenTransferBloc>(),
          child: TokenTransferConfirmPage(
            transferData: extra['transferData'] as TokenTransferData,
            transferParams: extra['transferParams'] as TokenTransferParams,
            walletAddress: extra['walletAddress'] as String,
            token: extra['token'] as TokenInfo?,
          ),
        );
      },
    ),

    // Transfer complete page
    GoRoute(
      path: '/transfer/complete',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TokenTransferCompletePage(
          transferData: extra['transferData'] as TokenTransferData,
          result: extra['result'] as TokenTransferResult,
          walletAddress: extra['walletAddress'] as String,
          token: extra['token'] as TokenInfo?,
          amount: extra['amount'] as String?,
        );
      },
    ),

    // Address page
    GoRoute(
      path: '/address',
      builder: (context, state) {
        final credentials = state.extra as WalletCredentials;
        return AddressPage(credentials: credentials);
      },
    ),
  ],
);

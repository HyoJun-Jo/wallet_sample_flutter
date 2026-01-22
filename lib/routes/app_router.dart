import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_manager.dart';
import '../di/injection_container.dart';
import '../features/auth/domain/entities/auth_entities.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/bloc/email_registration_bloc.dart';
import '../features/auth/presentation/bloc/sns_registration_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/email_registration_page.dart';
import '../features/auth/presentation/pages/password_reset_page.dart';
import '../features/auth/presentation/pages/sns_registration_page.dart';
import '../features/splash/presentation/bloc/splash_bloc.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../features/wallet/presentation/pages/create_wallet_page.dart';
import '../features/main_tab/presentation/pages/main_tab_page.dart';
import '../features/token/domain/entities/token_info.dart';
import '../features/token/presentation/pages/token_detail_page.dart';
import '../features/transfer/domain/entities/transfer.dart';
import '../features/transfer/presentation/bloc/transfer_bloc.dart';
import '../features/transfer/presentation/pages/send_token_page.dart';
import '../features/transfer/presentation/pages/transfer_confirm_page.dart';
import '../features/transfer/presentation/pages/transfer_complete_page.dart';
import '../features/signing/presentation/bloc/signing_bloc.dart';

// Route observer for tracking navigation
final routeObserver = RouteObserver<ModalRoute<dynamic>>();

// Auth-protected routes (redirect to login when session expires)
const _authProtectedPaths = ['/main', '/wallet', '/token', '/transfer'];

bool _isAuthProtectedPath(String path) {
  return _authProtectedPaths.any((p) => path.startsWith(p));
}

GoRouter createAppRouter(SessionManager sessionManager) => GoRouter(
  initialLocation: '/splash',
  observers: [routeObserver],
  refreshListenable: sessionManager,
  redirect: (context, state) {
    final isSessionExpired = sessionManager.status == AuthStatus.unauthenticated;
    final isAuthProtected = _isAuthProtectedPath(state.matchedLocation);

    // Redirect to login if session expired on protected routes
    if (isSessionExpired && isAuthProtected) {
      return '/login';
    }

    return null;
  },
  routes: [
    // Splash screen (app entry point)
    GoRoute(
      path: '/splash',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<SplashBloc>(),
        child: const SplashPage(),
      ),
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

    // Main tab page (token, browser, settings)
    GoRoute(
      path: '/main',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MainTabPage(
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

    // Token transfer page
    GoRoute(
      path: '/transfer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BlocProvider(
          create: (_) => sl<TransferBloc>(),
          child: SendTokenPage(
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
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<SigningBloc>()),
            BlocProvider(create: (_) => sl<TransferBloc>()),
          ],
          child: TransferConfirmPage(
            transferData: extra['transferData'] as TransferData,
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
        return TransferCompletePage(
          transferData: extra['transferData'] as TransferData,
          result: extra['result'] as TransferResult,
          walletAddress: extra['walletAddress'] as String,
          token: extra['token'] as TokenInfo?,
          amount: extra['amount'] as String?,
        );
      },
    ),
  ],
);

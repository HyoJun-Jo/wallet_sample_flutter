import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/email_login_usecase.dart';
import '../../domain/usecases/sns_token_login_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Login BLoC - handles email/SNS login, token refresh, and logout
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final EmailLoginUseCase _emailLoginUseCase;
  final SnsTokenLoginUseCase _snsTokenLoginUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final AuthRepository _authRepository;
  final LocalStorageService _localStorage;

  LoginBloc({
    required EmailLoginUseCase emailLoginUseCase,
    required SnsTokenLoginUseCase snsTokenLoginUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required AuthRepository authRepository,
    required LocalStorageService localStorage,
  })  : _emailLoginUseCase = emailLoginUseCase,
        _snsTokenLoginUseCase = snsTokenLoginUseCase,
        _refreshTokenUseCase = refreshTokenUseCase,
        _authRepository = authRepository,
        _localStorage = localStorage,
        super(const LoginInitial()) {
    on<LoginWithEmailRequested>(_onEmailLoginRequested);
    on<LoginWithSnsRequested>(_onSnsTokenLoginRequested);
    on<TokenRefreshRequested>(_onRefreshTokenRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<LoginCheckRequested>(_onCheckRequested);
    on<AutoLoginRequested>(_onAutoLoginRequested);
  }

  Future<void> _onEmailLoginRequested(
    LoginWithEmailRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _emailLoginUseCase(EmailLoginParams(
      email: event.email,
      password: event.password,
    ));

    await result.fold(
      (failure) async => emit(LoginError(message: failure.message)),
      (loginResult) async {
        switch (loginResult) {
          case EmailLoginSuccess(:final credentials):
            // Save user session
            await _authRepository.saveUserSession(
              email: event.email,
              loginType: LoginType.email,
            );
            // Save auto login preference
            await _localStorage.setBool(LocalStorageKeys.autoLogin, event.autoLogin);
            emit(LoginAuthenticated(credentials: credentials));
          case EmailUserNotRegistered(:final email):
            emit(EmailRegistrationRequired(email: email));
        }
      },
    );
  }

  Future<void> _onSnsTokenLoginRequested(
    LoginWithSnsRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _snsTokenLoginUseCase(SnsTokenLoginParams(
      snsToken: event.snsToken,
      loginType: event.loginType,
    ));

    await result.fold(
      (failure) async => emit(LoginError(message: failure.message)),
      (loginResult) async {
        switch (loginResult) {
          case SnsLoginSuccess(:final credentials):
            // Use email from SNS SDK directly, fall back to JWT extraction if not available
            final email = event.snsEmail ?? _extractEmailFromToken(credentials.accessToken);
            if (email != null) {
              await _authRepository.saveUserSession(
                email: email,
                loginType: event.loginType,
              );
            }
            // Save auto login preference
            await _localStorage.setBool(LocalStorageKeys.autoLogin, event.autoLogin);
            emit(LoginAuthenticated(credentials: credentials));
          case SnsUserNotFound(
              :final email,
              :final token,
              :final sixcode,
              :final language,
              :final timeout
            ):
            emit(SnsRegistrationRequired(
              email: email,
              token: token,
              sixcode: sixcode,
              language: language,
              timeout: timeout,
              loginType: event.loginType,
            ));
        }
      },
    );
  }

  /// Extract email from JWT token payload
  /// Checks 'email' field first, then falls back to 'sub'
  String? _extractEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // Try email field first (standard claim)
      if (data['email'] != null) {
        return data['email'] as String;
      }

      // Try preferred_username (some providers use this)
      if (data['preferred_username'] != null) {
        final username = data['preferred_username'] as String;
        if (username.contains('@')) {
          return username;
        }
      }

      // Fall back to sub (may be user ID for some providers like Kakao)
      return data['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onRefreshTokenRequested(
    TokenRefreshRequested event,
    Emitter<LoginState> emit,
  ) async {
    final savedCredentials = await _authRepository.getSavedCredentials();

    await savedCredentials.fold(
      (failure) async => emit(const LoginUnauthenticated()),
      (credentials) async {
        if (credentials == null) {
          emit(const LoginUnauthenticated());
          return;
        }

        final result = await _refreshTokenUseCase(RefreshTokenParams(
          refreshToken: credentials.refreshToken,
        ));

        result.fold(
          (failure) => emit(const LoginUnauthenticated()),
          (newCredentials) => emit(LoginAuthenticated(credentials: newCredentials)),
        );
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    await _authRepository.logout();
    await _localStorage.setBool(LocalStorageKeys.autoLogin, false);
    emit(const LoginUnauthenticated());
  }

  Future<void> _onAutoLoginRequested(
    AutoLoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    // Check if auto login is enabled
    final autoLogin = _localStorage.getBool(LocalStorageKeys.autoLogin) ?? false;
    if (!autoLogin) {
      emit(const LoginUnauthenticated());
      return;
    }

    emit(const LoginLoading());

    // Get saved credentials
    final savedCredentials = await _authRepository.getSavedCredentials();

    await savedCredentials.fold(
      (failure) async => emit(const LoginUnauthenticated()),
      (credentials) async {
        if (credentials == null) {
          emit(const LoginUnauthenticated());
          return;
        }

        // Try to refresh token to ensure it's valid
        final result = await _refreshTokenUseCase(RefreshTokenParams(
          refreshToken: credentials.refreshToken,
        ));

        result.fold(
          (failure) {
            // Token refresh failed, clear auto login and require manual login
            _localStorage.setBool(LocalStorageKeys.autoLogin, false);
            emit(const LoginUnauthenticated());
          },
          (newCredentials) => emit(LoginAuthenticated(credentials: newCredentials)),
        );
      },
    );
  }

  Future<void> _onCheckRequested(
    LoginCheckRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _authRepository.getSavedCredentials();

    result.fold(
      (failure) => emit(const LoginUnauthenticated()),
      (credentials) {
        if (credentials != null) {
          emit(LoginAuthenticated(credentials: credentials));
        } else {
          emit(const LoginUnauthenticated());
        }
      },
    );
  }
}

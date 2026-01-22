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
    on<SnsSignInRequested>(_onSnsSignInRequested);
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
            await _authRepository.saveUserSession(
              email: event.email,
              loginType: LoginType.email,
            );
            await _localStorage.setBool(LocalStorageKeys.autoLogin, event.autoLogin);
            emit(LoginAuthenticated(credentials: credentials));
          case EmailUserNotRegistered(:final email):
            emit(EmailRegistrationRequired(email: email));
        }
      },
    );
  }

  Future<void> _onSnsSignInRequested(
    SnsSignInRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _snsTokenLoginUseCase(SnsTokenLoginParams(
      loginType: event.loginType,
      autoLogin: event.autoLogin,
    ));

    await result.fold(
      (failure) async => emit(LoginError(message: failure.message)),
      (loginResult) async {
        switch (loginResult) {
          case SnsLoginSuccess(:final credentials, :final snsEmail):
            final email = snsEmail ?? _extractEmailFromToken(credentials.accessToken);
            if (email != null) {
              await _authRepository.saveUserSession(
                email: email,
                loginType: event.loginType,
              );
            }
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

  String? _extractEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (data['email'] != null) {
        return data['email'] as String;
      }

      if (data['preferred_username'] != null) {
        final username = data['preferred_username'] as String;
        if (username.contains('@')) {
          return username;
        }
      }

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
    final autoLogin = _localStorage.getBool(LocalStorageKeys.autoLogin) ?? false;
    if (!autoLogin) {
      emit(const LoginUnauthenticated());
      return;
    }

    emit(const LoginLoading());

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
          (failure) {
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

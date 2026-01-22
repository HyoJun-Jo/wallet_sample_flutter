import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_manager.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/usecases/email_login_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/sns_token_login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final EmailLoginUseCase _emailLoginUseCase;
  final SnsTokenLoginUseCase _snsTokenLoginUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final SessionManager _sessionManager;

  LoginBloc({
    required EmailLoginUseCase emailLoginUseCase,
    required SnsTokenLoginUseCase snsTokenLoginUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required SessionManager sessionManager,
  })  : _emailLoginUseCase = emailLoginUseCase,
        _snsTokenLoginUseCase = snsTokenLoginUseCase,
        _refreshTokenUseCase = refreshTokenUseCase,
        _sessionManager = sessionManager,
        super(const LoginInitial()) {
    on<LoginWithEmailRequested>(_onEmailLoginRequested);
    on<SnsSignInRequested>(_onSnsSignInRequested);
    on<TokenRefreshRequested>(_onRefreshTokenRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onEmailLoginRequested(
    LoginWithEmailRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _emailLoginUseCase(EmailLoginParams(
      email: event.email,
      password: event.password,
      autoLogin: event.autoLogin,
    ));

    result.fold(
      (failure) => emit(LoginError(message: failure.message)),
      (loginResult) {
        switch (loginResult) {
          case EmailLoginSuccess(:final credentials):
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
    ));

    result.fold(
      (failure) => emit(LoginError(message: failure.message)),
      (loginResult) {
        switch (loginResult) {
          case SnsLoginSuccess(:final credentials):
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

  Future<void> _onRefreshTokenRequested(
    TokenRefreshRequested event,
    Emitter<LoginState> emit,
  ) async {
    final result = await _refreshTokenUseCase(NoParams());

    result.fold(
      (failure) => emit(const LoginUnauthenticated()),
      (credentials) => emit(LoginAuthenticated(credentials: credentials)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    await _sessionManager.logout();
    emit(const LoginUnauthenticated());
  }
}

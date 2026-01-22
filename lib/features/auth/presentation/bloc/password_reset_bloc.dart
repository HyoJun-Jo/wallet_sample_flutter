import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/init_password_usecase.dart';
import '../../domain/usecases/send_verification_code_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import 'password_reset_event.dart';
import 'password_reset_state.dart';

/// Password reset BLoC
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final SendVerificationCodeUseCase _sendVerificationCodeUseCase;
  final VerifyCodeUseCase _verifyCodeUseCase;
  final InitPasswordUseCase _initPasswordUseCase;

  PasswordResetBloc({
    required SendVerificationCodeUseCase sendVerificationCodeUseCase,
    required VerifyCodeUseCase verifyCodeUseCase,
    required InitPasswordUseCase initPasswordUseCase,
  })  : _sendVerificationCodeUseCase = sendVerificationCodeUseCase,
        _verifyCodeUseCase = verifyCodeUseCase,
        _initPasswordUseCase = initPasswordUseCase,
        super(const PasswordResetInitial()) {
    on<PasswordResetCodeRequested>(_onPasswordResetCodeRequested);
    on<PasswordResetCodeVerified>(_onPasswordResetCodeVerified);
    on<PasswordResetSubmitted>(_onPasswordResetSubmitted);
  }

  Future<void> _onPasswordResetCodeRequested(
    PasswordResetCodeRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(const PasswordResetLoading());

    final result = await _sendVerificationCodeUseCase(
      SendVerificationCodeParams(
        email: event.email,
        template: 'initpassword', // Use initpassword template for password reset
      ),
    );

    result.fold(
      (failure) => emit(PasswordResetError(message: failure.message)),
      (_) => emit(PasswordResetCodeSent(email: event.email)),
    );
  }

  Future<void> _onPasswordResetCodeVerified(
    PasswordResetCodeVerified event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(const PasswordResetLoading());

    final result = await _verifyCodeUseCase(
      VerifyCodeParams(email: event.email, code: event.code),
    );

    result.fold(
      (failure) => emit(PasswordResetError(message: failure.message)),
      (_) => emit(PasswordResetCodeConfirmed(email: event.email, code: event.code)),
    );
  }

  Future<void> _onPasswordResetSubmitted(
    PasswordResetSubmitted event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(const PasswordResetLoading());

    final result = await _initPasswordUseCase(
      InitPasswordParams(
        email: event.email,
        password: event.password,
        code: event.code,
      ),
    );

    result.fold(
      (failure) => emit(PasswordResetError(message: failure.message)),
      (_) => emit(const PasswordResetSuccess()),
    );
  }
}

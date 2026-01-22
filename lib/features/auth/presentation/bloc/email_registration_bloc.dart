import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_email_usecase.dart';
import '../../domain/usecases/init_password_usecase.dart';
import '../../domain/usecases/register_with_email_usecase.dart';
import '../../domain/usecases/send_verification_code_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import 'email_registration_event.dart';
import 'email_registration_state.dart';

/// Email registration BLoC
class EmailRegistrationBloc
    extends Bloc<EmailRegistrationEvent, EmailRegistrationState> {
  final CheckEmailUseCase _checkEmailUseCase;
  final SendVerificationCodeUseCase _sendVerificationCodeUseCase;
  final VerifyCodeUseCase _verifyCodeUseCase;
  final InitPasswordUseCase _initPasswordUseCase;
  final RegisterWithEmailUseCase _registerWithEmailUseCase;

  EmailRegistrationBloc({
    required CheckEmailUseCase checkEmailUseCase,
    required SendVerificationCodeUseCase sendVerificationCodeUseCase,
    required VerifyCodeUseCase verifyCodeUseCase,
    required InitPasswordUseCase initPasswordUseCase,
    required RegisterWithEmailUseCase registerWithEmailUseCase,
  })  : _checkEmailUseCase = checkEmailUseCase,
        _sendVerificationCodeUseCase = sendVerificationCodeUseCase,
        _verifyCodeUseCase = verifyCodeUseCase,
        _initPasswordUseCase = initPasswordUseCase,
        _registerWithEmailUseCase = registerWithEmailUseCase,
        super(const EmailRegistrationInitial()) {
    on<EmailCheckRequested>(_onEmailCheckRequested);
    on<VerificationCodeRequested>(_onVerificationCodeRequested);
    on<CodeVerificationRequested>(_onCodeVerificationRequested);
    on<PasswordInitRequested>(_onPasswordInitRequested);
    on<EmailRegistrationSubmitted>(_onEmailRegistrationSubmitted);
  }

  Future<void> _onEmailCheckRequested(
    EmailCheckRequested event,
    Emitter<EmailRegistrationState> emit,
  ) async {
    emit(const EmailRegistrationLoading());

    final result = await _checkEmailUseCase(event.email);

    result.fold(
      (failure) => emit(EmailRegistrationError(message: failure.message)),
      (isAvailable) => isAvailable
          ? emit(EmailAvailable(email: event.email))
          : emit(EmailNotAvailable(email: event.email)),
    );
  }

  Future<void> _onVerificationCodeRequested(
    VerificationCodeRequested event,
    Emitter<EmailRegistrationState> emit,
  ) async {
    emit(const EmailRegistrationLoading());

    final result = await _sendVerificationCodeUseCase(
      SendVerificationCodeParams(
        email: event.email,
        template: 'verify',
      ),
    );

    result.fold(
      (failure) => emit(EmailRegistrationError(message: failure.message)),
      (_) => emit(VerificationCodeSent(email: event.email)),
    );
  }

  Future<void> _onCodeVerificationRequested(
    CodeVerificationRequested event,
    Emitter<EmailRegistrationState> emit,
  ) async {
    emit(const EmailRegistrationLoading());

    final result = await _verifyCodeUseCase(
      VerifyCodeParams(email: event.email, code: event.code),
    );

    result.fold(
      (failure) => emit(EmailRegistrationError(message: failure.message)),
      (_) => emit(CodeVerified(email: event.email, code: event.code)),
    );
  }

  Future<void> _onPasswordInitRequested(
    PasswordInitRequested event,
    Emitter<EmailRegistrationState> emit,
  ) async {
    emit(const EmailRegistrationLoading());

    final result = await _initPasswordUseCase(
      InitPasswordParams(
        email: event.email,
        password: event.password,
        code: event.code,
      ),
    );

    result.fold(
      (failure) => emit(EmailRegistrationError(message: failure.message)),
      (_) => emit(PasswordInitialized(email: event.email, code: event.code)),
    );
  }

  Future<void> _onEmailRegistrationSubmitted(
    EmailRegistrationSubmitted event,
    Emitter<EmailRegistrationState> emit,
  ) async {
    emit(const EmailRegistrationLoading());

    final result = await _registerWithEmailUseCase(
      RegisterWithEmailParams(
        email: event.email,
        password: event.password,
        code: event.code,
        overage: event.overage,
        agree: event.agree,
        collect: event.collect,
        thirdparty: event.thirdparty,
        advertise: event.advertise,
      ),
    );

    result.fold(
      (failure) => emit(EmailRegistrationError(message: failure.message)),
      (_) => emit(EmailRegistrationSuccess(email: event.email)),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_with_sns_usecase.dart';
import 'sns_registration_event.dart';
import 'sns_registration_state.dart';

/// SNS Registration BLoC - handles SNS user registration
class SnsRegistrationBloc
    extends Bloc<SnsRegistrationEvent, SnsRegistrationState> {
  final RegisterWithSnsUseCase _registerWithSnsUseCase;

  SnsRegistrationBloc({
    required RegisterWithSnsUseCase registerWithSnsUseCase,
  })  : _registerWithSnsUseCase = registerWithSnsUseCase,
        super(const SnsRegistrationInitial()) {
    on<SnsRegistrationSubmitted>(_onSnsRegistrationSubmitted);
  }

  Future<void> _onSnsRegistrationSubmitted(
    SnsRegistrationSubmitted event,
    Emitter<SnsRegistrationState> emit,
  ) async {
    emit(const SnsRegistrationLoading());

    final result = await _registerWithSnsUseCase(
      RegisterWithSnsParams(
        email: event.email,
        code: event.code,
        loginType: event.loginType,
        overage: event.overage,
        agree: event.agree,
        collect: event.collect,
        thirdparty: event.thirdparty,
        advertise: event.advertise,
      ),
    );

    result.fold(
      (failure) => emit(SnsRegistrationError(message: failure.message)),
      (_) => emit(SnsRegistrationSuccess(
        email: event.email,
        loginType: event.loginType,
      )),
    );
  }
}

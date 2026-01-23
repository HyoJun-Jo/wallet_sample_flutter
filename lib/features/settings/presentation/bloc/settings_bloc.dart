import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_user_settings_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetUserSettingsUseCase _getUserSettingsUseCase;
  final LogoutUseCase _logoutUseCase;

  SettingsBloc({
    required GetUserSettingsUseCase getUserSettingsUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _getUserSettingsUseCase = getUserSettingsUseCase,
        _logoutUseCase = logoutUseCase,
        super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await _getUserSettingsUseCase(NoParams());

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (userSettings) => emit(SettingsLoaded(userSettings: userSettings)),
    );
  }

  Future<void> _onLogoutRequested(
    SettingsLogoutRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLogoutInProgress());

    final result = await _logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (_) => emit(const SettingsLogoutSuccess()),
    );
  }
}

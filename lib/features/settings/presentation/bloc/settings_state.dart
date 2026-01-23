import 'package:equatable/equatable.dart';

import '../../domain/entities/user_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final UserSettings userSettings;

  const SettingsLoaded({required this.userSettings});

  @override
  List<Object?> get props => [userSettings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SettingsLogoutInProgress extends SettingsState {
  const SettingsLogoutInProgress();
}

class SettingsLogoutSuccess extends SettingsState {
  const SettingsLogoutSuccess();
}

import 'package:equatable/equatable.dart';

import '../../../../core/auth/entities/auth_entities.dart';

class UserSettings extends Equatable {
  final String email;
  final LoginType loginType;
  final String? walletAddress;
  final String appVersion;

  const UserSettings({
    required this.email,
    required this.loginType,
    this.walletAddress,
    required this.appVersion,
  });

  @override
  List<Object?> get props => [email, loginType, walletAddress, appVersion];
}

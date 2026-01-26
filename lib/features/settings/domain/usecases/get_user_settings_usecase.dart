import 'package:dartz/dartz.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/auth/entities/auth_entities.dart';
import '../../../../shared/wallet/domain/repositories/wallet_repository.dart';
import '../entities/user_settings.dart';

class GetUserSettingsUseCase implements UseCase<UserSettings, NoParams> {
  final LocalStorageService _localStorage;
  final WalletRepository _walletRepository;

  GetUserSettingsUseCase({
    required LocalStorageService localStorage,
    required WalletRepository walletRepository,
  })  : _localStorage = localStorage,
        _walletRepository = walletRepository;

  @override
  Future<Either<Failure, UserSettings>> call(NoParams params) async {
    try {
      // Get user info from local storage
      final email = _localStorage.getString(LocalStorageKeys.userEmail) ?? '';
      final loginTypeStr = _localStorage.getString(LocalStorageKeys.loginType);
      final loginType = LoginType.values.firstWhere(
        (e) => e.name == loginTypeStr,
        orElse: () => LoginType.email,
      );

      // Get wallet address
      String? walletAddress;
      final credentialsResult = await _walletRepository.getWalletCredentials();
      credentialsResult.fold(
        (failure) {},
        (credentials) {
          walletAddress = credentials?.address;
        },
      );

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      return Right(UserSettings(
        email: email,
        loginType: loginType,
        walletAddress: walletAddress,
        appVersion: appVersion,
      ));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

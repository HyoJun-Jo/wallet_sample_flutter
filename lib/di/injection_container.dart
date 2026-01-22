import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_session_manager.dart';
import '../core/constants/app_constants.dart';
import '../core/crypto/secure_channel_service.dart';
// SNS Auth (OAuth SDK)
import '../features/auth/data/datasources/sns_auth_datasource.dart';
import '../features/auth/domain/repositories/sns_auth_repository.dart';
import '../features/auth/data/repositories/sns_auth_repository_impl.dart';
import '../core/network/api_client.dart';
import '../core/network/interceptors/auth_interceptor.dart';
import '../core/network/interceptors/error_interceptor.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/local_storage.dart';
import '../core/chain/chain_repository.dart';

// Auth
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/email_login_usecase.dart';
import '../features/auth/domain/usecases/sns_token_login_usecase.dart';
import '../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../features/auth/domain/usecases/register_with_sns_usecase.dart';
import '../features/auth/domain/usecases/check_email_usecase.dart';
import '../features/auth/domain/usecases/send_verification_code_usecase.dart';
import '../features/auth/domain/usecases/verify_code_usecase.dart';
import '../features/auth/domain/usecases/init_password_usecase.dart';
import '../features/auth/domain/usecases/register_with_email_usecase.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/bloc/sns_registration_bloc.dart';
import '../features/auth/presentation/bloc/email_registration_bloc.dart';
import '../features/auth/presentation/bloc/password_reset_bloc.dart';

// Splash
import '../features/splash/presentation/bloc/splash_bloc.dart';

// Wallet
import '../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../features/wallet/domain/repositories/wallet_repository.dart';
import '../features/wallet/domain/usecases/create_wallet_usecase.dart';
import '../features/wallet/presentation/bloc/wallet_bloc.dart';

// Token
import '../features/token/data/datasources/token_remote_datasource.dart';
import '../features/token/data/datasources/token_local_datasource.dart';
import '../features/token/data/repositories/token_repository_impl.dart';
import '../features/token/domain/repositories/token_repository.dart';
import '../features/token/domain/usecases/get_all_tokens_usecase.dart';
import '../features/token/presentation/bloc/token_bloc.dart';

// Transfer
import '../features/transfer/data/datasources/transfer_remote_datasource.dart';
import '../features/transfer/data/repositories/transfer_repository_impl.dart';
import '../features/transfer/domain/repositories/transfer_repository.dart';
import '../features/transfer/domain/usecases/send_token_usecase.dart';
import '../features/transfer/presentation/bloc/transfer_bloc.dart';

// Signing
import '../features/signing/data/datasources/signing_remote_datasource.dart';
import '../features/signing/data/repositories/signing_repository_impl.dart';
import '../features/signing/domain/repositories/signing_repository.dart';
import '../features/signing/domain/usecases/sign_usecase.dart';
import '../features/signing/domain/usecases/sign_typed_data_usecase.dart';
import '../features/signing/domain/usecases/sign_hash_usecase.dart';
import '../features/signing/domain/usecases/sign_eip1559_usecase.dart';
import '../features/signing/domain/usecases/get_nonce_usecase.dart';
import '../features/signing/domain/usecases/estimate_gas_usecase.dart';
import '../features/signing/domain/usecases/get_suggested_gas_fees_usecase.dart';
import '../features/signing/domain/usecases/send_signed_transaction_usecase.dart';
import '../features/signing/presentation/bloc/signing_bloc.dart';

// Browser
import '../features/browser/data/datasources/bookmark_local_datasource.dart';
import '../features/browser/data/repositories/bookmark_repository_impl.dart';
import '../features/browser/domain/repositories/bookmark_repository.dart';
import '../features/browser/domain/usecases/get_bookmarks_usecase.dart';
import '../features/browser/domain/usecases/add_bookmark_usecase.dart';
import '../features/browser/domain/usecases/remove_bookmark_usecase.dart';
import '../features/browser/domain/usecases/is_bookmarked_usecase.dart';
import '../features/browser/presentation/bloc/browser_bloc.dart';

// History
import '../features/history/data/datasources/history_remote_datasource.dart';
import '../features/history/data/datasources/history_local_datasource.dart';
import '../features/history/data/repositories/history_repository_impl.dart';
import '../features/history/domain/repositories/history_repository.dart';
import '../features/history/domain/usecases/get_token_transactions_usecase.dart';
import '../features/history/domain/usecases/get_nft_transactions_usecase.dart';
import '../features/history/presentation/bloc/history_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Storage
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageService(),
  );

  // Chain Repository
  sl.registerLazySingleton<ChainRepository>(
    () => ChainRepositoryImpl(),
  );

  // Auth Session Manager
  sl.registerLazySingleton<AuthSessionManager>(
    () => AuthSessionManager(),
  );

  // Interceptors
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      secureStorage: sl(),
      sessionManager: sl(),
    ),
  );
  sl.registerLazySingleton<ErrorInterceptor>(
    () => ErrorInterceptor(),
  );

  // Network - WaaS API
  sl.registerLazySingleton<ApiClient>(
    () => DioApiClient(
      authInterceptor: sl(),
      errorInterceptor: sl(),
      baseUrl: AppConstants.apiBaseUrl,
    ),
  );

  // Crypto - uses WaaS API
  sl.registerLazySingleton<SecureChannelService>(
    () => SecureChannelService(
      apiClient: sl(),
      storage: sl(),
    ),
  );

  // SNS Auth (OAuth SDK)
  sl.registerLazySingleton<SnsAuthDataSource>(
    () => SnsAuthDataSourceImpl(),
  );
  sl.registerLazySingleton<SnsAuthRepository>(
    () => SnsAuthRepositoryImpl(dataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
      localStorage: sl(),
      secureChannelService: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => EmailLoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => SnsTokenLoginUseCase(
        snsAuthRepository: sl(),
        authRepository: sl(),
      ));
  sl.registerLazySingleton(() => RefreshTokenUseCase(repository: sl()));
  sl.registerLazySingleton(() => RegisterWithSnsUseCase(repository: sl()));
  sl.registerLazySingleton(() => CheckEmailUseCase(repository: sl()));
  sl.registerLazySingleton(() => SendVerificationCodeUseCase(repository: sl()));
  sl.registerLazySingleton(() => VerifyCodeUseCase(repository: sl()));
  sl.registerLazySingleton(() => InitPasswordUseCase(repository: sl()));
  sl.registerLazySingleton(() => RegisterWithEmailUseCase(repository: sl()));

  // BLoC
  sl.registerFactory(() => LoginBloc(
        emailLoginUseCase: sl(),
        snsTokenLoginUseCase: sl(),
        refreshTokenUseCase: sl(),
        authRepository: sl(),
        localStorage: sl(),
      ));
  sl.registerFactory(() => SnsRegistrationBloc(
        registerWithSnsUseCase: sl(),
      ));
  sl.registerFactory(() => EmailRegistrationBloc(
        checkEmailUseCase: sl(),
        sendVerificationCodeUseCase: sl(),
        verifyCodeUseCase: sl(),
        initPasswordUseCase: sl(),
        registerWithEmailUseCase: sl(),
      ));
  sl.registerFactory(() => PasswordResetBloc(
        sendVerificationCodeUseCase: sl(),
        verifyCodeUseCase: sl(),
        initPasswordUseCase: sl(),
      ));

  // DataSource
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
      localStorage: sl(),
      secureChannelService: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => CreateWalletUseCase(sl()));

  // BLoC
  sl.registerFactory(() => WalletBloc(
        createWalletUseCase: sl(),
        walletRepository: sl(),
      ));

  sl.registerFactory(() => SplashBloc(
        secureStorage: sl(),
        localStorage: sl(),
        walletRepository: sl(),
      ));

  // DataSources
  sl.registerLazySingleton<TokenRemoteDataSource>(
    () => TokenRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<TokenLocalDataSource>(
    () => TokenLocalDataSourceImpl(prefs: sl()),
  );

  // Repository
  sl.registerLazySingleton<TokenRepository>(
    () => TokenRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetAllTokensUseCase(sl()));

  // BLoC
  sl.registerFactory(() => TokenBloc(
        getAllTokensUseCase: sl(),
      ));

  // DataSource
  sl.registerLazySingleton<TransferRemoteDataSource>(
    () => TransferRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(
      remoteDataSource: sl(),
      chainService: sl(),
      apiClient: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => CreateTransferDataUseCase(sl()));
  sl.registerLazySingleton(() => SendTransactionUseCase(sl()));

  // BLoC
  sl.registerFactory(() => TransferBloc(
        createTransferDataUseCase: sl(),
        sendTransactionUseCase: sl(),
      ));

  // DataSource
  sl.registerLazySingleton<SigningRemoteDataSource>(
    () => SigningRemoteDataSourceImpl(
      apiClient: sl(),
      secureChannelService: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<SigningRepository>(
    () => SigningRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => SignUseCase(sl()));
  sl.registerLazySingleton(() => SignTypedDataUseCase(sl()));
  sl.registerLazySingleton(() => SignHashUseCase(sl()));
  sl.registerLazySingleton(() => SignEip1559UseCase(sl()));
  sl.registerLazySingleton(() => GetNonceUseCase(sl()));
  sl.registerLazySingleton(() => EstimateGasUseCase(sl()));
  sl.registerLazySingleton(() => GetSuggestedGasFeesUseCase(sl()));
  sl.registerLazySingleton(() => SendSignedTransactionUseCase(sl()));

  // BLoC
  sl.registerFactory(() => SigningBloc(
        signUseCase: sl(),
        signTypedDataUseCase: sl(),
        signHashUseCase: sl(),
        signingRepository: sl(),
      ));

  // DataSource
  sl.registerLazySingleton<BookmarkLocalDataSource>(
    () => BookmarkLocalDataSourceImpl(localStorage: sl()),
  );

  // Repository
  sl.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(localDataSource: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => GetBookmarksUseCase(sl()));
  sl.registerLazySingleton(() => AddBookmarkUseCase(sl()));
  sl.registerLazySingleton(() => RemoveBookmarkUseCase(sl()));
  sl.registerLazySingleton(() => IsBookmarkedUseCase(sl()));

  // BLoC
  sl.registerFactory(() => BrowserBloc());

  // DataSources
  sl.registerLazySingleton<HistoryRemoteDataSource>(
    () => HistoryRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<HistoryLocalDataSource>(
    () => HistoryLocalDataSourceImpl(prefs: sl()),
  );

  // Repository
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetTokenTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetNftTransactionsUseCase(sl()));

  // BLoC
  sl.registerFactory(() => HistoryBloc(
        getTokenTransactionsUseCase: sl(),
        getNftTransactionsUseCase: sl(),
      ));

  await sl<LocalStorageService>().init();
  await sl<ChainRepository>().load();
}

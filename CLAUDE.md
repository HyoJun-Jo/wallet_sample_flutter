# Wallet Sample Flutter - 프로젝트 가이드

## 프로젝트 개요
wallet_base_flutter를 참조하여 만든 샘플 지갑 앱입니다.
Clean Architecture와 BLoC 패턴을 사용합니다.

## 참조 프로젝트
- **Base**: `../wallet_base_flutter`
- 구조, 컨벤션, 패턴은 base 프로젝트를 따릅니다.

## 아키텍처

### 디렉토리 구조
```
lib/
├── core/                    # 공통 유틸리티
│   ├── constants/           # 상수 (app_constants.dart, api_endpoints.dart)
│   ├── errors/              # Failure, Exception 클래스
│   ├── network/             # API 클라이언트, Interceptor
│   ├── storage/             # SecureStorage, LocalStorage
│   ├── usecases/            # UseCase 베이스 클래스
│   └── utils/               # 유틸리티 함수
├── di/                      # 의존성 주입 (injection_container.dart)
├── features/                # 기능별 모듈
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/ # Remote/Local DataSource
│       │   ├── models/      # DTO (JSON serialization)
│       │   └── repositories/# Repository 구현체
│       ├── domain/
│       │   ├── entities/    # 비즈니스 엔티티 (Equatable)
│       │   ├── repositories/# Repository 인터페이스
│       │   └── usecases/    # UseCase 클래스
│       └── presentation/
│           ├── bloc/        # BLoC, Event, State
│           ├── pages/       # 페이지/스크린
│           └── widgets/     # 기능별 위젯
├── routes/                  # GoRouter 설정
├── shared/                  # 공유 위젯
└── main.dart
```

### 레이어 규칙
| 레이어 | 의존 가능 | 의존 불가 |
|--------|-----------|-----------|
| Domain | 없음 (순수 Dart) | Data, Presentation, Flutter |
| Data | Domain | Presentation |
| Presentation | Domain, Data | - |

## 코딩 컨벤션

### 네이밍
```dart
// 파일명: snake_case
user_profile_page.dart
auth_repository_impl.dart

// 클래스: PascalCase
class UserProfilePage {}
class AuthRepositoryImpl {}

// 변수/함수: camelCase
final userName = '';
void getUserData() {}

// Private: underscore prefix
String _privateField;
void _privateMethod() {}

// 상수: lowerCamelCase (k prefix 없이)
const primaryColor = Color(0xFF...);
```

### 클래스 패턴

#### Entity (Domain)
```dart
class Wallet extends Equatable {
  final String address;
  final String network;

  const Wallet({required this.address, required this.network});

  @override
  List<Object?> get props => [address, network];
}
```

#### UseCase (Domain)
```dart
class CreateWalletUseCase implements UseCase<WalletResult, CreateWalletParams> {
  final WalletRepository _repository;

  CreateWalletUseCase(this._repository);

  @override
  Future<Either<Failure, WalletResult>> call(CreateWalletParams params) {
    return _repository.createWallet(params.email, params.password);
  }
}
```

#### Repository Interface (Domain)
```dart
abstract class WalletRepository {
  Future<Either<Failure, WalletResult>> createWallet(String email, String password);
}
```

#### Repository Impl (Data)
```dart
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl({required WalletRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, WalletResult>> createWallet(...) async {
    try {
      final result = await _remoteDataSource.createWallet(...);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

#### BLoC (Presentation)
```dart
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final CreateWalletUseCase _createWalletUseCase;

  WalletBloc({required CreateWalletUseCase createWalletUseCase})
      : _createWalletUseCase = createWalletUseCase,
        super(const WalletInitial()) {
    on<WalletCreateRequested>(_onCreateRequested);
  }

  Future<void> _onCreateRequested(
    WalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _createWalletUseCase(params);
    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (wallet) => emit(WalletCreated(wallet: wallet)),
    );
  }
}
```

#### Event/State 분리
```dart
// wallet_event.dart
abstract class WalletEvent extends Equatable {
  const WalletEvent();
}

class WalletCreateRequested extends WalletEvent {
  final String email;
  const WalletCreateRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

// wallet_state.dart
abstract class WalletState extends Equatable {
  const WalletState();
}

class WalletInitial extends WalletState {
  const WalletInitial();
  @override
  List<Object?> get props => [];
}
```

## 의존성 주입 (GetIt)

### 등록 순서
```dart
// injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  // 1. Core (Storage, Network)
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<ApiClient>(() => DioApiClient(...));

  // 2. DataSources
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(apiClient: sl()),
  );

  // 3. Repositories
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDataSource: sl()),
  );

  // 4. UseCases
  sl.registerLazySingleton(() => CreateWalletUseCase(sl()));

  // 5. BLoCs (Factory - 새 인스턴스)
  sl.registerFactory(() => WalletBloc(createWalletUseCase: sl()));
}
```

## 라우팅 (GoRouter)

```dart
// routes/app_router.dart
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/wallet',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<WalletBloc>(),
        child: const WalletListPage(),
      ),
    ),
  ],
);
```

## 에러 처리

### Failure 타입
```dart
ServerFailure    // API 오류
NetworkFailure   // 네트워크 연결 오류
CacheFailure     // 캐시 오류
AuthFailure      // 인증 오류
WalletFailure    // 지갑 관련 오류
ValidationFailure // 유효성 검사 오류
```

### Either 패턴 (dartz)
```dart
// 항상 Either<Failure, Success>로 반환
Future<Either<Failure, Wallet>> getWallet();

// 사용
result.fold(
  (failure) => handleError(failure),
  (success) => handleSuccess(success),
);
```

## 주요 의존성

| 패키지 | 용도 |
|--------|------|
| flutter_bloc | 상태 관리 |
| equatable | 값 비교 |
| dartz | Either, 함수형 |
| get_it | 의존성 주입 |
| dio | HTTP 클라이언트 |
| go_router | 라우팅 |
| flutter_secure_storage | 보안 저장소 |
| shared_preferences | 로컬 저장소 |

## 새 Feature 추가 절차

1. **Domain 레이어 먼저**
   - `entities/` - 엔티티 정의
   - `repositories/` - Repository 인터페이스
   - `usecases/` - UseCase 구현

2. **Data 레이어**
   - `models/` - DTO (fromJson, toJson, toEntity)
   - `datasources/` - Remote/Local DataSource
   - `repositories/` - Repository 구현체

3. **Presentation 레이어**
   - `bloc/` - Event, State, BLoC
   - `pages/` - 페이지
   - `widgets/` - 위젯

4. **의존성 등록**
   - `di/injection_container.dart`에 등록

5. **라우트 추가**
   - `routes/app_router.dart`에 추가

## 개발 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 분석
flutter analyze

# 테스트 실행
flutter test

# 빌드
flutter build apk --debug
flutter build ios --debug
```

## 환경 설정

```bash
# .env.dev (개발)
API_BASE_URL=https://dev-api.example.com

# .env.prod (프로덕션)
API_BASE_URL=https://api.example.com
```

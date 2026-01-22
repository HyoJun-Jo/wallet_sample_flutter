# Known Issues

## Auth Interceptor 구조 검토 필요

**파일:**
- `lib/core/network/interceptors/auth_interceptor.dart`
- `lib/core/network/interceptors/error_interceptor.dart`

**이슈:**
1. ErrorInterceptor와 AuthInterceptor 간 401/403 처리 중복
2. 인터셉터 순서: `[Log, Auth, Error]` → 에러 흐름은 역순 `Error → Auth`
3. ErrorInterceptor가 먼저 401/403을 AuthException으로 변환 후 AuthInterceptor가 refresh 시도
4. 구조가 혼란스러움 - 역할 분리 필요

**제안:**
- ErrorInterceptor에서 401/403 처리 제거
- AuthInterceptor가 인증 관련 에러 전담
- 또는 인터셉터 순서 재검토

**우선순위:** 낮음 (현재 동작은 함)

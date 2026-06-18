# Networking

The networking layer handles all HTTP communication between the Flutter app and the FastAPI backend. It is built on Dio and lives entirely under `lib/core/network/`.

## Key abstractions

### ApiClient

**File:** `lib/core/network/api_client.dart`

A thin wrapper around `Dio` that exposes typed HTTP methods (`get`, `post`, `put`, `delete`). Every method catches `DioException` and re-throws it as a typed `AppFailure` via `ErrorPresenter.fromDio()`.

```dart
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
  baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
  tokenProvider: ref.watch(authTokenProviderProvider),
));
```

Configuration:
- Base URL from `AppConfig.apiBaseUrl` (set via `.env` or `--dart-define`)
- 60-second connect/receive/send timeouts
- `Accept: application/json` header
- Debug-mode `LogInterceptor` (prints via `debugPrint`)

### AuthInterceptor

**File:** `lib/core/network/interceptors/auth_interceptor.dart`

A Dio `Interceptor` that attaches the Bearer token to every request and handles 401 responses with a single-flight token refresh and request queue.

**Request flow:**
1. `onRequest` calls `tokenProvider.getAccessToken()` and sets the `Authorization` header
2. If a `TransientAuthRefreshException` is thrown (network down), the request proceeds without a token

**401 recovery flow:**
1. First 401 triggers a token refresh via `_refreshCompleter` (single-flight)
2. Concurrent 401s are queued in `_queuedRequests` and wait for the refresh to complete
3. On success: the original request is retried with the new token, and queued requests are replayed
4. On failure: `clearSession()` is called and all queued requests fail with a 401

**Transient refresh handling:** If `getAccessToken()` throws `TransientAuthRefreshException` during a 401 retry, the interceptor does NOT clear the session. It propagates the original error so the caller can handle it without forcing a logout.

### RefreshingAuthTokenProvider

**File:** `lib/core/network/auth_token_provider.dart`

Implements `AuthTokenProvider` (the interface shared with `AuthInterceptor`). Manages Supabase session lifecycle:

- Reads the current session from `Supabase.instance.client.auth.currentSession`
- Checks expiry via both `session.isExpired` and a manual JWT `exp` claim decoder (with 10-second skew)
- Refreshes via `client.auth.refreshSession()` with single-flight dedup (`_refreshInflight`)
- Saves/clears the token in `AuthTokenStorage` (backed by `SecureKvStore`)
- Throws `TransientAuthRefreshException` on transport failures (timeout, DNS) so callers can distinguish from "no session"

### ErrorPresenter

**File:** `lib/core/errors/error_presenter.dart`

Maps `DioException` to the appropriate `AppFailure` subclass. Used by `ApiClient` and can be used directly in repositories for non-Dio error paths.

### ConnectivityMonitor

**File:** `lib/core/network/connectivity_monitor.dart`

A `StreamProvider<bool>` backed by `connectivity_plus` that emits `true` when any network interface is available and `false` when all are down.

```dart
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});
```

The `OfflineBanner` widget (also in this file) is rendered as a `Stack` overlay above `MaterialApp.router` in `App.build()`. It shows a red banner with "You are offline" when `connectivityProvider` emits `false`.

## How it works

1. **Bootstrap** (`lib/bootstrap.dart`) creates `AppConfig`, `AppPreferences`, and `SecureKvStore`, then injects them as `ProviderScope` overrides
2. `apiClientProvider` reads `AppConfig.apiBaseUrl` and `authTokenProviderProvider` to construct the `ApiClient`
3. `authTokenProviderProvider` creates a `RefreshingAuthTokenProvider` backed by `AuthTokenStorage`
4. Feature repositories (e.g., `DiscoverRepository`, `ChatsRepository`) read `apiClientProvider` and call its HTTP methods
5. All errors flow through `ErrorPresenter.fromDio()` before reaching controllers or the UI

## Integration points

- **Supabase** -- `RefreshingAuthTokenProvider` reads and refreshes sessions from `Supabase.instance.client.auth`
- **SecureKvStore** -- tokens are persisted via `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android)
- **FlatmatesEndpoints** -- all API path constants live in `lib/core/config/endpoints.dart`

## Key source files

| File | Purpose |
|------|---------|
| `lib/core/network/api_client.dart` | Dio wrapper with error mapping |
| `lib/core/network/interceptors/auth_interceptor.dart` | Token attachment + 401 refresh queue |
| `lib/core/network/auth_token_provider.dart` | Supabase session management + JWT expiry check |
| `lib/core/network/connectivity_monitor.dart` | Network state stream + OfflineBanner |
| `lib/core/errors/error_presenter.dart` | DioException to AppFailure mapping |
| `lib/core/providers.dart` | Root provider graph (apiClientProvider, authTokenProviderProvider) |
| `lib/core/config/endpoints.dart` | API path constants |

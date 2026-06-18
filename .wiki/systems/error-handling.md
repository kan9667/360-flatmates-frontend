# Error Handling

The error handling system provides typed, localized error propagation from the network layer to the UI. It lives under `lib/core/errors/` and enforces strict rules: no `error.toString()` in pages, no empty catch blocks, and all errors rendered through `AppFailure.userMessage()`.

## Key abstractions

### AppFailure sealed class

**File:** `lib/core/errors/app_failure.dart`

A sealed class hierarchy that represents every category of error the app can encounter. Each subclass carries the original error for logging and a `userMessage(UserMessageL10n)` method for localized display.

| Subclass | HTTP Code | Label | Usage |
|----------|-----------|-------|-------|
| `NetworkFailure` | -- | `network` | Timeouts, DNS failures, no connectivity |
| `AuthExpiredFailure` | 401 | `auth_expired` | Token expired or invalid |
| `ServerFailure` | 5xx | `server($statusCode)` | Backend internal errors |
| `PermissionFailure` | 403 | `permission` | Forbidden access |
| `NotFoundFailure` | 404 | `not_found` | Resource not found |
| `ValidationFailure` | 422 | `validation` | Field-level validation errors (carries `fieldMessages` map) |
| `RateLimitFailure` | 429 | `rate_limit` | Too many requests |
| `ConflictFailure` | 409 | `conflict` | Duplicate or conflicting state |
| `UploadFailure` | -- | `upload` | File upload errors (carries optional `reason`) |
| `UnknownFailure` | -- | `unknown` | Catch-all for unexpected errors |

Every subclass stores `underlyingError` and `stackTrace` for logging/crash reporting.

### ErrorPresenter

**File:** `lib/core/errors/error_presenter.dart`

A static mapper that converts `DioException` to the appropriate `AppFailure` subclass. Used by `ApiClient` and can be used directly in repositories.

**Mapping logic:**
- `connectionTimeout` / `sendTimeout` / `receiveTimeout` / `connectionError` / `badCertificate` -- `NetworkFailure`
- Status code mapping: 400 (ValidationFailure), 401 (AuthExpiredFailure), 403 (PermissionFailure), 404 (NotFoundFailure), 409 (ConflictFailure), 422 (ValidationFailure with field messages), 429 (RateLimitFailure), 5xx (ServerFailure)
- `unknown` type -- checks for `SocketException`, `HandshakeException`, `HttpException`, or string markers like "failed host lookup", "connection refused", "timed out" to classify as `NetworkFailure`

**Server message extraction:** `_extractServerMessage()` tries `data['detail']` (string or nested map), then `data['message']`.

**422 field-level parsing:** `_fromValidationResponse()` parses `data['detail']` or `data['errors']` as a `Map<String, String>` for `ValidationFailure.fieldMessages`.

### UserMessageL10n

**File:** `lib/core/errors/app_failure.dart`

A plain data class that bridges `AppFailure` to the generated `AppLocalizations`. It carries one localized string per error category (e.g., `errorNetwork`, `errorAuthExpired`, `errorServer`).

This decouples `core/errors/` from the generated l10n package.

### AppLocalizationsX extension

**File:** `lib/core/errors/l10n_bridge.dart`

An extension on `AppLocalizations` that creates a `UserMessageL10n` instance:

```dart
final l10n = AppLocalizations.of(context);
final message = failure.userMessage(l10n.toUserMessageL10n());
```

Also provides `resolveAuthError()` for resolving `failure:`-prefixed error keys from `AuthController` into localized messages.

### FlatmatesAsyncView

**File:** `lib/features/shared/presentation/flatmates_async_view.dart`

A shared widget that renders `AsyncValue<T>` into loading, data, empty, and error states. Error states display the `AppFailure.userMessage()` text with a retry action. Used throughout the app instead of manual `AsyncValue.when()` blocks.

## Architecture guardrails

The `scripts/banned_patterns.sh` script enforces:
- No `error.toString()` in page files
- No `apiClientProvider` in page files (use a repository)
- No `Supabase.instance` in page files
- Page files under 500 lines

**No empty catch blocks.** Every `catch` must log via `debugPrint('ClassName.methodName: $e')`. In fire-and-forget contexts, use `unawaited()`.

## How it works

1. A repository calls `apiClient.get('/endpoint')`
2. `ApiClient` catches `DioException` and throws `ErrorPresenter.fromDio(e, st)`
3. The repository catches `AppFailure` and re-throws or returns it
4. The controller catches `AppFailure` and updates state (e.g., `AsyncError`)
5. The widget uses `FlatmatesAsyncView` which calls `failure.userMessage(l10n.toUserMessageL10n())`
6. The localized message is displayed to the user with a retry option

## Integration points

- **ApiClient** -- `ErrorPresenter.fromDio()` is called in every HTTP method
- **Repositories** -- catch `AppFailure` and propagate to controllers
- **Controllers** -- set `AsyncError` state with the `AppFailure`
- **FlatmatesAsyncView** -- renders error state from `AsyncValue`
- **AnalyticsService** -- `recordError()` sends errors to Firebase Crashlytics
- **AppLocalizations** -- provides localized error strings via `toUserMessageL10n()`

## Key source files

| File | Purpose |
|------|---------|
| `lib/core/errors/app_failure.dart` | AppFailure sealed class + UserMessageL10n |
| `lib/core/errors/error_presenter.dart` | DioException to AppFailure mapping |
| `lib/core/errors/l10n_bridge.dart` | AppLocalizations extension + resolveAuthError |
| `lib/features/shared/presentation/flatmates_async_view.dart` | Async state renderer |
| `scripts/banned_patterns.sh` | Architecture guardrail enforcement |

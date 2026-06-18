# Patterns and conventions

## State management — Riverpod

- **NotifierProvider** / **AsyncNotifierProvider** for controllers with explicit state and named methods. Examples: `DiscoverFeedController`, `ListingDraftController`, `MessagesController`, `AuthController`, `BootstrapController`, `OnboardingController`, `SettingsController`.
- **FamilyNotifier** for parameterized controllers (e.g., `MessagesController` per conversation).
- **Provider** for repositories and services (injected via `ref.watch`).
- **FutureProvider** / **FutureProvider.family** for one-shot async data (swipe profiles, conversations, notifications, visits).
- **StreamProvider** for streams (e.g., `connectivityProvider`).
- **StateProvider** for local UI state — loading flags, visibility toggles, form values. Defined at file level as `final _myFlagProvider = StateProvider<bool>((ref) => false);`.
- **PagedState\<T\>** for paginated data with initial/refresh/load-more loading states.
- **OptimisticUpdate.perform\<T\>()** for optimistic UI writes with rollback on failure.

### Rules

- Read state via `ref.watch()` in `build()`, write state via `ref.read(provider.notifier).state = value` in callbacks.
- Never use `ref.read()` to read state in `build()` — it creates non-reactive snapshots.
- Never mutate state inside `build()` — move mutations to event handlers.
- Never use `setState()` in `ConsumerStatefulWidget` — use `StateProvider` instead.
- After write operations, invalidate the relevant provider rather than manually syncing widget state.

## Business logic placement

Business logic goes in controllers, not widgets. Widgets call `ref.read(controllerProvider.notifier).method()` instead of calling repositories directly. Create an `application/` layer controller when a feature needs orchestration beyond simple data fetching.

## Networking

- Use the shared `ApiClient` from `core/network/api_client.dart` — all authenticated requests go through it.
- All API path constants are centralized in `FlatmatesEndpoints` (`core/config/endpoints.dart`). Never hardcode backend paths.
- Error handling for HTTP failures uses `ErrorPresenter.fromDio()` which maps `DioException` to typed `AppFailure`.
- JWT token management is handled automatically by `AuthInterceptor` — no manual token attachment needed.

## Error handling

- Use `AppFailure` sealed class hierarchy and `FlatmatesAsyncView` for error display.
- Never use `error.toString()` in presentation code — enforced by `scripts/banned_patterns.sh`.
- Never use empty catch blocks. Every `catch` must log via `debugPrint('ClassName.methodName: $e')`.
- In fire-and-forget contexts, wrap with `unawaited()` instead of empty catches.

## UI conventions

- Use `Flatmates*` shared widgets from `features/shared/presentation/` (barrel-exported via `components.dart`) instead of duplicating `Scaffold`/`SafeArea`/`ListView`/async-state patterns.
- Use `FlatmatesNetworkImage` instead of raw `Image.network` — enforced by `scripts/banned_patterns.sh`.
- Use `AppMotion` for all animation durations and curves. Do not hard-code durations or `Curves`.
- Use `Listener` (not `GestureDetector`) for press-detection when wrapping interactive children.
- Always use `const` constructors for widgets that don't change — `SizedBox`, `Padding`, `Icon`, `Text`, etc.
- Add `tooltip` to every `IconButton` for accessibility.
- Avoid heavy computations in `build()`. Extract loops to private methods or pre-compute in providers.
- Use `AppLocalizations.of(context)` for all user-facing strings. Add new keys to both `app_en.arb` and `app_hi.arb`.
- Design tokens live in `lib/core/theme/` (AppSpacing, AppRadius, AppShadows, AppMotion, AppTypography, AppSemanticColors, AppGradients). Barrel-exported via `theme.dart`.

## DTO pattern

When backend JSON doesn't map cleanly to domain models, use a DTO class in the feature's `data/` layer (e.g., `PropertyListingDto` → `PropertyListing`). Keep backend-specific parsing details in DTOs; keep domain models clean.

## Code generation

- Freezed and json_serializable are used for domain models. After modifying freezed-annotated models, run `dart run build_runner build --delete-conflicting-outputs`.
- Generated files (`.freezed.dart`, `.g.dart`) are committed to the repo.

## Architecture guardrails (enforced by `scripts/banned_patterns.sh`)

- No `error.toString()` in page files
- No `apiClientProvider` in page files (use a repository)
- No `Supabase.instance` in page files
- No raw `Image.network` in features (use `FlatmatesNetworkImage`)
- No page files over 500 lines
- No direct repository calls in widgets (use controllers)

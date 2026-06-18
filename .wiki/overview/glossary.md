# Glossary

Project-specific terms and types used throughout the 360 FlatMates codebase.

## Error Handling

### AppFailure

A sealed class hierarchy in `lib/core/errors/app_failure.dart` representing typed application errors. Subclasses: `NetworkFailure`, `AuthExpiredFailure`, `ServerFailure`, `PermissionFailure`, `NotFoundFailure`, `ValidationFailure`, `RateLimitFailure`, `ConflictFailure`, `UploadFailure`, `UnknownFailure`. Each provides a `label` for logging and `userMessage()` for localized display. Repositories throw these instead of raw `DioException`.

### ErrorPresenter

A utility class in `lib/core/errors/error_presenter.dart` that converts `DioException` into typed `AppFailure` subclasses. Maps HTTP status codes (401, 403, 404, 409, 422, 429, 5xx) and Dio error types (timeout, connection) to the appropriate failure type. Handles field-level validation parsing from 422 responses.

### UserMessageL10n

A bridge class in `lib/core/errors/app_failure.dart` that decouples `AppFailure` from generated `AppLocalizations`. Provides string properties for each error type. Pages use `FlatmatesAsyncView` which calls `failure.userMessage(l10n)` to render localized error text.

## Networking

### ApiClient

The shared HTTP client in `lib/core/network/api_client.dart`. Wraps a `Dio` instance configured with base URL, timeouts (60s), and the interceptor chain. Exposes typed `get()`, `post()`, `put()`, `delete()` methods. All repositories use this client; direct `Dio` usage in features is banned.

### AuthTokenProvider

An abstract interface in `lib/core/network/auth_token_provider.dart` defining `getAccessToken()` and `clearSession()`. The concrete implementation, `RefreshingAuthTokenProvider`, manages Supabase session refresh with single-flight deduplication and JWT expiry detection (with 10-second skew). Throws `TransientAuthRefreshException` for non-auth refresh failures to avoid forcing logout on flaky networks.

### FlatmatesEndpoints

A constants class in `lib/core/config/endpoints.dart` centralizing all API path strings. Prevents path drift and typos across repositories. Covers auth, bootstrap, profiles, conversations, swipes, properties, visits, notifications, SSE, and feedback endpoints. Some paths are static constants; others are methods that accept IDs (e.g., `conversation(int id)` returns `/flatmates/conversations/$id`).

### SseService

A service in `lib/core/network/sse_service.dart` that maintains a persistent Server-Sent Events connection to `/flatmates/sse`. Receives real-time event notifications from the backend (new messages, listing updates, etc.). Connected after login and disconnected on logout. Uses a token refresher callback so reconnects always use a fresh JWT.

### SseEvent

A typed event model emitted by `SseService`. Parsed from the SSE stream and routed by `sseEventRouterProvider` to invalidate relevant Riverpod providers (e.g., conversations, notifications).

## State Management

### PagedState\<T\>

A generic pagination state class in `lib/core/domain/paged_state.dart`. Tracks `items`, `isInitialLoading`, `isRefreshing`, `isLoadingMore`, `hasMore`, and `error`. Used by list-backed screens (discover feed, notifications, conversations) for consistent pagination behavior with `copyWith()` for immutable updates.

### OptimisticUpdate

A helper class in `lib/core/domain/optimistic_update.dart` implementing the optimistic UI pattern. `OptimisticUpdate.perform()` immediately applies a new state, runs an async action, and rolls back on failure. Used in controllers for like/unlike, send message, and other write operations.

### AuthState

A model representing the current authentication state. Tracks `status` (checking, authenticated, unauthenticated), `isLoggedIn`, `needsPassword` (for OTP flow), and `authStage` (e.g., `profileCompletion`). Emitted by `AuthController` and consumed by the router redirect chain.

### AuthStage

An enum representing the current stage of the authentication state machine. Values include `profileCompletion` (mandatory fields missing) and other stages that gate routing. Determined by the backend via `/users/me/auth-state?app=flatmates`.

### BootstrapData

A domain model loaded from `GET /flatmates/bootstrap` on every app start. Contains the user's profile, server-driven catalogs (room types, furnishing options, etc.), and count summaries. Managed by `BootstrapController` (`lib/features/bootstrap/`).

### OnboardingState

A multi-step state machine model for the onboarding flow (`lib/features/onboarding/`). Tracks the current step, collected data (role, location, preferences), and draft persistence via `OnboardingDraftStorage`.

### ConversationSummaryModel

A Freezed model representing a chat conversation summary. Contains conversation ID, peer user info, last message preview, unread count, and timestamps. Used by the conversations list and chat thread pages.

## Domain Models

### PropertyListing

A domain model representing a property listing. Constructed from backend JSON via `PropertyListingDto` (DTO pattern). Contains flat details, location, rent, amenities, photos, owner info, and availability.

### SwipeAction

A domain enum for swipe gestures in the card deck (`lib/features/swipe/`). Represents like, dislike, or super-like actions.

### CompatibilityResult

The output of the client-side matching algorithm in `lib/core/compatibility/`. Contains an overall percentage score and per-dimension breakdown across 6 weighted dimensions (lifestyle, food habits, cleanliness, schedule, social, budget).

### UserMode

A string enum representing the user's role in the app. Values: `room_poster` (lists property), `co_hunter` (seeks flat), `open_to_both` (flexible). Determines which bottom nav tabs are visible and which features are accessible.

### VisitStatus

A domain enum for visit request states in `lib/features/visits/`. Tracks whether a visit is pending, confirmed, rescheduled, or declined.

## Theme and Design

### AppSemanticColors

A constants class in `lib/core/theme/app_semantic_colors.dart` providing context-aware color tokens. Includes accent, surface, text, border, success, error, warning, frost blur, and frost overlay values. Light and dark mode variants are derived automatically.

### AppMotion

A constants class in `lib/core/theme/app_motion.dart` defining animation durations and curves used throughout the app. Tokens include `pageTransition` (250ms), `buttonPress` (150ms), `cardAppear` (300ms), `chipSelect` (150ms), `matchCelebration` (600ms), and corresponding `Curve` values. All animations must use these tokens instead of hardcoded durations.

### AppPalette

A class in `lib/core/theme/app_palette.dart` defining the three available color palettes: electric indigo (default), ember coral, and monsoon teal. Users can switch palettes in settings.

### AppTheme

A class in `lib/core/theme/app_theme.dart` with a static `build()` method that produces a complete `ThemeData` from a brightness and palette. Configures Material 3 color scheme, typography (Fraunces headlines, Inter body), card theme, dialog theme, platform-specific page transitions, and all component themes.

### Flatmates*

A library of 18 reusable widgets in `lib/features/shared/presentation/`, barrel-exported via `components.dart`. Key widgets:

| Widget | Purpose |
|--------|---------|
| `FlatmatesScreen` | Unified page scaffold with SafeArea, padding, and 200ms fade-in |
| `FlatmatesAsyncView` | Renders `AsyncValue<T>` into loading/data/empty/error states |
| `FlatmatesNetworkImage` | Network image with placeholder and error fallback |
| `FlatmatesCard` | Content card with interactive press glow |
| `FlatmatesChip` | Filter/tag chip with `.choice()` variant and selection spring |
| `FlatmatesSearchBar` | Search input with focus glow and scale lift |
| `FlatmatesSkeleton` | Shimmer loading placeholder (`.card`, `.list`, `.feed`, `.profile`) |
| `FlatmatesErrorState` | Error display with retry action |
| `FlatmatesEmptyState` | Empty state with illustration and breathing icon |
| `FlatmatesBottomActionBar` | Sticky bottom CTA bar with frosted-glass backdrop |
| `FlatmatesBottomSheet` | Styled bottom sheet container |
| `FlatmatesSegmentedControl` | Tab-style selector with sliding pill indicator |
| `FlatmatesStepProgress` | Multi-step progress indicator |
| `FlatmatesPriceText` | Formatted price display |
| `FlatmatesTrustBadge` | Verified/trust indicator badge |
| `FlatmatesProfileMiniCard` | Compact profile row |
| `FlatmatesListingMiniCard` | Compact listing row |
| `FlatmatesHeader` | Page header with optional back button and actions |

## Services

### AppConfigService

A service in `lib/core/app_config/app_config_service.dart` that checks for app updates by calling `POST /versions/check` on the backend. Returns force-update, optional-update, or up-to-date status. Drives the `ForceUpdatePage` and `OptionalUpdateDialog`.

### NotificationService

A service in `lib/core/notifications/notification_service.dart` managing Firebase Cloud Messaging. Handles foreground and background message processing, local notification display, FCM token registration with the backend, and deep link routing from notification taps. Initialized after login, disposed on logout.

### DeepLinkService

A service in `lib/core/deep_links/deep_link_service.dart` parsing incoming HTTP deep links via the `app_links` package. Supports `/flatmates/listing/{id}` (flat details) and `/flatmates/chat/{id}` (chat thread). Handles both cold start (initial link on app launch) and warm start (stream listener while app is running).

### ImageUploadService

A service in `lib/core/storage/image_upload_service.dart` that uploads photos and video tours (up to 50MB) through the backend API (Cloudinary). Used by listing creation and profile photo editing.

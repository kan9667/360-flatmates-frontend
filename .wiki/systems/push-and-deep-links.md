# Push Notifications & Deep Links

This page covers push notification delivery, local notification display, deep link routing, remote app configuration, and the centralized API endpoint registry.

## Push Notifications

### NotificationService

**File:** `lib/core/notifications/notification_service.dart`

Manages Firebase Cloud Messaging (FCM) push notifications and local notification display.

**Initialization flow:**
1. `initializeLocalNotifications()` -- called in `bootstrap.dart` before `runApp()`. Sets up `flutter_local_notifications` with Android (`@mipmap/ic_launcher`) and iOS (`DarwinInitializationSettings`). Creates the `flatmates_messages` notification channel on Android.
2. `initialize()` -- called after auth login (via `ref.listen` on `authControllerProvider`). Requests notification permissions, subscribes to foreground/background message streams, registers the FCM token with the backend.

**Message handling:**
- **Foreground:** `FirebaseMessaging.onMessage` listens for incoming messages. If the message has a `notification` payload, it shows a local notification. For data-only messages, it extracts `title`/`body` from the data map.
- **Background:** `_firebaseMessagingBackgroundHandler` (annotated with `@pragma('vm:entry-point')`) initializes Firebase and local notifications, then shows a local notification for data-only messages.
- **App opened from notification:** `FirebaseMessaging.onMessageOpenedApp` extracts the `route` from `message.data` and stores it in `_pendingRoute`.
- **Cold start:** `getInitialMessage()` checks if the app was launched from a notification.

**Token management:**
- On token refresh, sends the new token to `POST /notifications/devices/register` with `platform` (ios/android)
- `clearToken()` calls `DELETE /notifications/devices/unregister` on logout (best-effort)

**Pending route:** `consumePendingRoute()` returns and clears the stored route, which the router's redirect chain uses to navigate to the notification target.

### OfflineBanner

**File:** `lib/core/network/connectivity_monitor.dart`

A `ConsumerWidget` rendered as a `Stack` overlay in `App.build()`. Shows a red banner with "You are offline" when `connectivityProvider` emits `false`. Uses `AppSemanticColors.error` background and the localized `youAreOffline` string.

---

## Deep Links

### DeepLinkService

**File:** `lib/core/deep_links/deep_link_service.dart`

Parses incoming HTTP deep links via the `app_links` package and routes them through GoRouter.

**Supported paths:**

| External URL | Internal route | Description |
|---|---|---|
| `https://the360ghar.com/flatmates/listing/{id}` | `/flat-details/{id}` | Open a property listing |
| `https://the360ghar.com/flatmates/chat/{id}` | `/chats/{id}` | Open a chat thread |

**Lifecycle:**
- `init()` -- called in `App.initState()` after the first frame. Sets up `getInitialLink()` (cold start) and `uriLinkStream` (warm start).
- `dispose()` -- cancels the stream subscription.

**Validation:** IDs must be positive integers with no leading zeros (except "0" itself, which is rejected). Invalid IDs are silently ignored.

**URL builders:**
- `DeepLinkService.listingUrl(listingId)` -- `https://the360ghar.com/flatmates/listing/{id}`
- `DeepLinkService.chatUrl(chatId)` -- `https://the360ghar.com/flatmates/chat/{id}`
- `DeepLinkService.flatmatesUrl({city})` -- `https://the360ghar.com/flatmates?city={city}`

**Integration with router:** Deep link paths are stored in `_pendingDeepLinkPath` and consumed by the router's redirect chain via `DeepLinkService.consumePendingDeepLink()`.

---

## App Configuration

### AppConfig

**File:** `lib/core/config/app_config.dart`

An immutable configuration object created from environment variables (`.env` file or `--dart-define` flags).

**Fields:**

| Field | Source | Required | Description |
|-------|--------|----------|-------------|
| `environment` | `APP_ENV` | No | `dev`, `staging`, or `prod` (default: `dev`) |
| `apiBaseUrl` | `API_BASE_URL` | Yes | Backend API base URL |
| `supabaseUrl` | `SUPABASE_URL` | Yes | Supabase project URL |
| `supabaseAnonKey` | `SUPABASE_PUBLISHABLE_KEY` | Yes | Supabase anonymous key |
| `enableDebugLogs` | `ENABLE_DEBUG_LOGS` | No | Enable debug logging (default: `true` in debug mode) |
| `googleWebClientId` | `GOOGLE_WEB_CLIENT_ID` | No | Google OAuth web client ID |
| `googleIosClientId` | `GOOGLE_IOS_CLIENT_ID` | No | Google OAuth iOS client ID |

If required fields are missing, the app shows a `_ConfigErrorApp` with setup instructions.

### AppConfigService

**File:** `lib/core/app_config/app_config_service.dart`

Handles remote version checking via `POST /versions/check`:

- Sends current app version, build number, platform, and app name (`flatmates`)
- Returns a `VersionCheckResult` with `updateAvailable`, `isMandatory`, `latestVersion`, `downloadUrl`, `releaseNotes`
- Maps to `AppUpdateStatus`: `upToDate`, `optionalUpdate`, or `forceUpdate`
- Respects per-version optional-update dismissal (persisted in `AppPreferences`)

On `forceUpdate`: navigates to `ForceUpdatePage` (full-screen, blocks all interaction).
On `optionalUpdate`: shows `OptionalUpdateDialog` with release notes and dismiss option.

### FlatmatesEndpoints

**File:** `lib/core/config/endpoints.dart`

Centralized API path constants organized by domain. All repositories use these instead of inline path strings.

**Groups:**
- **Auth/User:** `/users/me`, `/users/me/auth-state?app=flatmates`, `/users/location`, `/auth/identifier-status`, `/auth/last-method`, `/auth/config`
- **Bootstrap/Profile:** `/flatmates/bootstrap`, `/flatmates/profile`
- **Catalogs:** `/flatmates/catalogs`
- **Blocks:** `/flatmates/blocks`, `/flatmates/blocks/{id}`
- **Conversations:** `/flatmates/conversations`, `/flatmates/conversations/{id}`, `/flatmates/conversations/{id}/messages`, `/flatmates/conversations/{id}/mark-read`, `/flatmates/conversations/{id}/qna`
- **Swipes:** `/flatmates/swipes`, `/flatmates/likes`, `/flatmates/outgoing-likes`, `/flatmates/profile-views`
- **Properties:** `/properties`, `/properties/{id}`, `/properties/me`
- **Visits:** `/visits`, `/visits/{id}`
- **Notifications:** `/flatmates/notifications`, `/flatmates/notifications/{id}`, `/notifications/devices/register`, `/notifications/devices/unregister`
- **Other:** `/versions/check`, `/bugs`, `/flatmates/sse`, `/flatmates/profiles`, `/flatmates/listings/{id}/society-tags/votes`

### Constants

**File:** `lib/core/config/constants.dart`

App-wide constants: privacy policy URL, terms of service URL, support email, App Store ID, Play Store ID, and URL builders for store links.

## How it works

1. `bootstrap.dart` loads `.env` via `EnvLoader`, creates `AppConfig.fromEnvironment()`
2. `AppConfig` is injected as a `ProviderScope` override
3. On auth login, `NotificationService.initialize()` requests permissions and registers the FCM token
4. On app open, `AppConfigService.checkForUpdates()` checks for version updates
5. `DeepLinkService.init()` starts listening for incoming deep links
6. Push notification routes and deep link paths are consumed by the router's redirect chain

## Key source files

| File | Purpose |
|------|---------|
| `lib/core/notifications/notification_service.dart` | FCM + local notifications |
| `lib/core/deep_links/deep_link_service.dart` | Deep link parsing + routing |
| `lib/core/app_config/app_config_service.dart` | Version check + update flows |
| `lib/core/app_config/force_update_page.dart` | Force update full-screen page |
| `lib/core/app_config/optional_update_dialog.dart` | Optional update dialog |
| `lib/core/config/app_config.dart` | Environment configuration |
| `lib/core/config/endpoints.dart` | API path constants |
| `lib/core/config/constants.dart` | App-wide constants |
| `lib/core/config/env_loader.dart` | .env file loader |
| `lib/core/network/connectivity_monitor.dart` | OfflineBanner widget |

# Analytics & Storage

This page covers the analytics, crash reporting, and persistent storage subsystems under `lib/core/analytics/` and `lib/core/storage/`.

## Analytics

### AnalyticsService

**File:** `lib/core/analytics/analytics_service.dart`

A wrapper around Firebase Analytics and Firebase Crashlytics. Created via a static async factory:

```dart
final service = await AnalyticsService.create(firebaseReady: true);
```

When Firebase is not configured (missing `google-services.json` / `GoogleService-Info.plist`), a disabled instance is returned that silently no-ops on all calls.

**Initialization:**
- Hooks `FlutterError.onError` and `PlatformDispatcher.instance.onError` to Crashlytics
- Sets custom Crashlytics keys: `app_version`, `build_number`, `platform`
- Provided via `analyticsServiceProvider` (overridden in `bootstrap.dart`)

**Analytics methods:**
- `logEvent(name:, parameters:)` -- generic event logging
- `setUserId(id)` -- sets user ID on both Analytics and Crashlytics
- `logScreenView(screenName:)` -- screen view tracking
- Convenience methods: `logAppOpen()`, `logLogin()`, `logSignup()`, `logLogout()`, `logNotificationReceived()`, `logNotificationOpened()`, `logForceUpdateShown()`, `logOptionalUpdateShown()`

**Crashlytics methods:**
- `recordError(error, stack, {fatal})` -- records non-fatal or fatal errors
- `setCustomKey(key, value)` -- sets custom diagnostic keys

### AnalyticsEvents

**File:** `lib/core/analytics/analytics_events.dart`

Constants for all tracked event names, organized by domain:

| Domain | Events |
|--------|--------|
| App lifecycle | `app_open` |
| Auth | `auth_started`, `auth_completed`, `auth_failed` |
| Onboarding | `onboarding_started`, `mode_selected`, `onboarding_completed` |
| Discovery | `discover_card_viewed`, `listing_opened`, `listing_liked`, `listing_shortlisted` |
| Swipe | `swipe_like`, `swipe_pass`, `match_created` |
| Chat | `chat_started`, `message_sent`, `photo_sent` |
| Visits | `visit_requested`, `visit_confirmed`, `visit_cancelled`, `visit_completed` |
| Listings | `listing_draft_started`, `listing_submitted`, `listing_approved_seen`, `listing_paused`, `listing_renewed` |
| Share | `share_card_shared`, `deep_link_opened` |
| Profile | `profile_edited`, `avatar_changed` |
| Settings | `theme_changed`, `locale_changed`, `user_blocked`, `user_reported`, `user_signed_out` |

### AnalyticsProps

Standard property keys: `city`, `mode`, `listing_id`, `conversation_id`, `visit_id`, `source`, `match_percentage_bucket`, `network_status`.

---

## Storage

### AppPreferences

**File:** `lib/core/storage/app_preferences.dart`

A thin wrapper around `SharedPreferences` for non-sensitive user preferences. Created asynchronously in `bootstrap.dart` and injected via `appPreferencesProvider`.

**PrefKeys constants:**
- Theme: `theme_mode`, `theme_palette`
- Locale: `locale_language_code`, `locale_country_code`
- Privacy: `privacy_hide_last_name`, `privacy_hide_exact_location`
- Notifications: `notif_new_messages`, `notif_visit_reminders`, `notif_new_matches`, `notif_listing_updates`, `notif_promotions`, `notif_permission_requested`
- Auth: `last_auth_method`, `last_auth_identifier`

### SecureKvStore

**File:** `lib/core/storage/secure_kv_store.dart`

A thin wrapper around `flutter_secure_storage` for sensitive data. Uses Keychain on iOS and EncryptedSharedPreferences on Android.

Methods: `readString(key)`, `writeString(key, value)`, `delete(key)`.

Injected via `secureStoreProvider` (overridden in `bootstrap.dart`).

### AuthTokenStorage

**File:** `lib/core/storage/auth_token_storage.dart`

Manages the auth token lifecycle on top of `SecureKvStore`:

- `read()` -- reads the stored token
- `save(token)` -- writes the token and emits it on the `changes` stream
- `clear()` -- deletes the token and emits `null` on the `changes` stream

The `changes` stream allows other parts of the app to react to token changes.

### ImageUploadService

**File:** `lib/core/storage/image_upload_service.dart`

Handles image/video picking and uploading through the backend API (which routes to Cloudinary).

**Media picking:**
- `pickImages(limit)` -- multi-image picker (quality 80%)
- `pickFromCamera()` -- single camera capture
- `pickVideo(maxDuration)` -- video picker (default 60s max)

**Video validation:**
- Max 50MB file size
- Max 60 seconds duration
- Min 15 seconds duration

**Upload methods** (all return `UploadResult` sealed type):
- `uploadProfilePhoto(file)` -- folder: `avatars`, visibility: `public`
- `uploadListingPhoto(file)` -- folder: `property_image`, visibility: `public`
- `uploadChatPhoto(file)` -- folder: `chats`, visibility: `private`
- `uploadVideoTour(file)` -- folder: `property_video`, visibility: `public`

**Upload flow:**
1. Creates `FormData` with the file, folder, and visibility
2. POSTs to `/upload` via the shared Dio client (120s timeout)
3. Tracks progress via `onSendProgress` callback
4. Returns `UploadSuccess(url)` or `UploadFailure(reason)`

Injected via `imageUploadServiceProvider`.

### OnboardingDraftStorage

**File:** `lib/core/storage/onboarding_draft_storage.dart`

Persists the onboarding state machine data as JSON in `SharedPreferences` under the key `onboarding_state`. This allows users to resume onboarding if they close the app mid-flow.

Methods: `load()` (returns `Map<String, dynamic>?`), `save(data)`, `clear()`.

## How it works

1. `bootstrap.dart` creates `AppPreferences` and `SecureKvStore` asynchronously
2. Both are injected as `ProviderScope` overrides
3. `AuthTokenStorage` wraps `SecureKvStore` for the auth token
4. `ImageUploadService` wraps the shared `ApiClient` for uploads
5. `AnalyticsService` wraps Firebase Analytics + Crashlytics
6. Feature controllers access these via Riverpod providers

## Key source files

| File | Purpose |
|------|---------|
| `lib/core/analytics/analytics_service.dart` | Firebase Analytics + Crashlytics wrapper |
| `lib/core/analytics/analytics_events.dart` | Event name constants + property keys |
| `lib/core/storage/app_preferences.dart` | SharedPreferences wrapper |
| `lib/core/storage/secure_kv_store.dart` | flutter_secure_storage wrapper |
| `lib/core/storage/auth_token_storage.dart` | Auth token persistence |
| `lib/core/storage/image_upload_service.dart` | Image/video upload via backend |
| `lib/core/storage/onboarding_draft_storage.dart` | Onboarding state persistence |
| `lib/core/providers.dart` | Root provider graph |

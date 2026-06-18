# Settings Feature

**Active contributors:** Saksham Mittal, Ravi Sahu

## Purpose

The settings feature manages user preferences including theme mode, color palette, locale, privacy toggles, notification preferences, and account actions (change password, blocked users, account deletion). All preferences are persisted to `SharedPreferences` and applied globally via Riverpod.

## Directory Layout

```
lib/features/settings/
├── settings_page.dart                 # Settings menu with grouped sections
├── settings_controller.dart           # Notifier managing SettingsState
├── domain/
│   └── settings_state.dart            # Freezed SettingsState model
├── presentation/
│   ├── change_password_page.dart      # Change password form
│   ├── blocked_users_page.dart        # Blocked users list
│   ├── delete_account_page.dart       # Account deletion flow
│   └── privacy_security_page.dart     # Privacy settings
```

## Key Abstractions

- **`SettingsState`** -- Freezed immutable state class holding all user preferences: `themeMode`, `palette`, `locale`, `hideLastName`, `hideExactLocation`, and five notification toggles.
- **`SettingsController`** -- `Notifier<SettingsState>` that loads preferences from `SharedPreferences` on build and exposes named update methods for each preference.
- **`settingsControllerProvider`** -- global Riverpod provider for the settings controller, consumed by the theme system, locale delegate, and settings page.

## How It Works

### SettingsState

The `SettingsState` Freezed class defines:

| Field | Default | Purpose |
|-------|---------|---------|
| `themeMode` | `ThemeMode.light` | Light, dark, or system theme |
| `palette` | `AppPalette.inkOnPaper` | Color palette (ink-on-paper, electric indigo, ember coral, monsoon teal) |
| `locale` | `Locale('en')` | App language (English or Hindi) |
| `loaded` | `false` | Whether preferences have been loaded from storage |
| `hideLastName` | `false` | Privacy toggle to hide last name |
| `hideExactLocation` | `false` | Privacy toggle to hide exact location |
| `notifNewMessages` | `true` | Notification toggle for new messages |
| `notifVisitReminders` | `true` | Notification toggle for visit reminders |
| `notifNewMatches` | `true` | Notification toggle for new matches |
| `notifListingUpdates` | `true` | Notification toggle for listing updates |
| `notifPromotions` | `false` | Notification toggle for promotions |

### SettingsController

`SettingsController` extends `Notifier<SettingsState>` and:

1. **Loads** preferences from `SharedPreferences` on first build via `Future.microtask(() => load())`
2. **Persists** each preference change immediately to `SharedPreferences`
3. **Updates** state via `state = state.copyWith(...)` to trigger reactive rebuilds

Each preference has a dedicated update method (e.g., `updateThemeMode()`, `updatePalette()`, `updateLocale()`).

### Settings Page

`SettingsPage` is a `ConsumerWidget` organized into four groups:

**Account:**
- Edit Profile -> `/profile/edit`
- Change Password -> `/change-password`
- Privacy & Security -> `/privacy-security`
- Preferences -> bottom sheet with theme, palette, locale, and privacy toggles
- Delete Account -> `/delete-account`

**App:**
- Notification Settings -> `/notification-settings`
- Blocked Users -> `/blocked-users`

**Legal:**
- About -> system about dialog with app version
- Terms & Conditions -> `/terms-of-service`

**Standalone:**
- Logout -> `AuthController.signOut()`

### Preferences Bottom Sheet

The preferences are presented in a `FlatmatesBottomSheet` with:

- **Theme mode** -- `FlatmatesSegmentedControl` with System/Light/Dark options
- **Palette** -- `FlatmatesChip` wrap with the four available palettes
- **Language** -- `FlatmatesSegmentedControl` with English/Hindi options
- **Privacy toggles** -- `SwitchListTile` for hide last name and hide exact location

### Theme & Palette Application

The `SettingsController` state is consumed by:
- `MaterialApp.router`'s `themeMode` property
- `ColorScheme.fromSeed()` which uses the selected palette's seed color
- The locale delegate which reads `settings.locale`

## Integration Points

- **SharedPreferences** -- all preferences are persisted via `AppPreferences` (wrapper around `SharedPreferences`) using `PrefKeys` constants.
- **Theme System** -- `core/theme/app_palette.dart` defines `AppPalette` enum and `AppPaletteX.fromStorage()` for deserialization.
- **Auth** -- logout and account deletion delegate to `AuthController`.
- **Profile** -- edit profile navigates to the profile feature's edit page.

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/features/settings/settings_page.dart` | Settings menu with grouped sections |
| `lib/features/settings/settings_controller.dart` | Notifier managing all user preferences |
| `lib/features/settings/domain/settings_state.dart` | Freezed SettingsState model |
| `lib/features/settings/presentation/change_password_page.dart` | Change password form |
| `lib/features/settings/presentation/blocked_users_page.dart` | Blocked users list |
| `lib/features/settings/presentation/delete_account_page.dart` | Account deletion flow |
| `lib/core/storage/app_preferences.dart` | SharedPreferences wrapper |
| `lib/core/theme/app_palette.dart` | Palette enum and storage helpers |

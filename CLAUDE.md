# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

360 FlatMates — a Flutter mobile client for flatmate-finding in India. Uses Supabase for auth/storage and a FastAPI backend monolith at `../backend` for all business logic and product data.

- **Flutter:** 3.35.2 (pinned via FVM in `.fvmrc`)
- **Dart SDK:** ^3.11.0
- **App ID:** `com.the360ghar.flatmates`

## Commands

```bash
# Setup
cp .env.example .env          # then fill in SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, API_BASE_URL
flutter pub get

# Run
flutter run

# Quality
flutter analyze
flutter test

# Localization (auto-generated on build, but can be triggered manually)
flutter gen-l10n

# Maestro E2E (requires MAESTRO_PHONE, MAESTRO_PASSWORD, etc. env vars)
maestro test .maestro/flatmates_e2e.yaml
maestro test maestro/e2e.yaml
```

## Architecture

### Feature-first structure under `lib/`

```
lib/
  main.dart                     → entry point
  bootstrap.dart                → DI setup, Supabase init, ProviderScope
  app/
    app.dart                    → MaterialApp.router
    app_shell.dart              → bottom nav shell (5 visible tabs)
    router/app_router.dart      → GoRouter with auth/bootstrap redirects
  core/                         → app-wide plumbing only (no feature logic)
    providers.dart              → global Riverpod providers
    config/                     → AppConfig, constants, env loader
    network/                    → Dio client, auth/error interceptors
    notifications/              → Firebase Messaging
    storage/                    → SharedPreferences, secure storage, image upload
    theme/                      → Material 3 theme with palette switching
    compatibility/              → client-side matching algorithm (6 weighted dimensions)
  features/                     → each feature owns its controller, repo, models, pages
    auth/                       → Supabase auth (phone+password, OTP)
    bootstrap/                  → loads /flatmates/bootstrap (profile + catalogs + counts)
    onboarding/                 → multi-step state machine (mode → info → photo → quiz → budget → dealbreakers)
    discover/                   → listing feed + map view
    swipe/                      → Tinder-like card deck
    chats/                      → conversations + messages (polling, no realtime)
    listings/                   → create/manage listings
    visits/                     → schedule/confirm/reschedule visits
    notifications/              → notification list
    profile/                    → profile view/edit
    settings/                   → theme mode, palette, locale, privacy
    shared/presentation/        → FlatmatesAvatar, GradientActionButton, InfoPill, etc.
```

### State management — Riverpod

- `StateNotifierProvider` for controllers with complex state (`AuthController`, `BootstrapController`, `OnboardingController`, `SettingsController`)
- `Provider` for repositories and services (injected via `ref.watch`)
- `FutureProvider` / `FutureProvider.family` for async data fetching (discover listings, swipe profiles, chats, notifications, visits)
- Three providers overridden at `ProviderScope` root: `appConfigProvider`, `appPreferencesProvider`, `secureStoreProvider`
- After write operations, **invalidate** the relevant provider rather than manually syncing widget state

### Routing — GoRouter

- `StatefulShellRoute.indexedStack` with 6 branches: `/discover`, `/swipe`, `/chats`, `/visits` (hidden tab, accessed from profile), `/post`, `/profile`
- Auth redirect chain: checking → `/splash`, unauthenticated → `/enter-phone`, onboarding incomplete → `/onboarding`
- Router refreshes on `authControllerProvider` and `bootstrapControllerProvider` changes

### Networking

- Shared `Dio` client from `core/network/api_client.dart` — all authenticated requests go through this
- `AuthInterceptor` attaches Bearer token, handles 401 with automatic token refresh (Supabase session)
- `ErrorInterceptor` maps DioException types to user-friendly messages
- Backend paths are relative to `AppConfig.apiBaseUrl` (set via `.env` or `--dart-define`)

### Auth flow

1. Phone input → password login or OTP via Supabase
2. After auth, `GET /users/me` validates user exists in backend
3. `BootstrapController` fetches `/flatmates/bootstrap` for profile + catalogs
4. If `onboardingCompleted == false`, router redirects to onboarding flow

### Theme and localization

- Material 3 via `ColorScheme.fromSeed()` with 3 palettes: electric indigo (default), ember coral, monsoon teal
- Google Fonts: Sora (headlines), Plus Jakarta Sans (body)
- Light/dark/system theme modes, persisted to SharedPreferences
- ARB-based l10n: English (`app_en.arb`, template) and Hindi (`app_hi.arb`), generated to `lib/l10n/gen/`

### Key patterns

- No code generation (no freezed, no json_serializable). Models are hand-written with `fromJson` factories.
- Image uploads go to Supabase Storage via `ImageUploadService` (supports photos and video tours up to 50MB).
- Compatibility scoring runs client-side in `core/compatibility/` with 6 weighted dimensions.
- No realtime/WebSocket — chat uses polling via `FutureProvider`.

## Cross-repo dependencies

- **`../backend`** — FastAPI monolith, source of truth for API contracts. If new fields/endpoints are needed, implement there first.
- **`../real-estate-admin-dashboard`** — admin dashboard for moderation workflows.
- Do not fork API contracts locally in the Flutter app.

## Rules from AGENTS.md

- Use real backend APIs only — no mock repositories, fake payloads, or hardcoded catalogs.
- Keep business metadata server-driven via `/api/v1/flatmates/catalogs`.
- `lib/core` is for technical plumbing only — don't leak feature logic there.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.
- All authenticated requests must flow through the shared Dio client and auth interceptor.
- Maintain light/dark/system theme support and palette switching.
- Keep English and Hindi localization in sync for primary flows.
- Use meaningful `Key` values on interactive widgets for Maestro stability.
- Update `docs/` when API surface, architecture, theme/localization strategy, auth flow, or Maestro assumptions change.

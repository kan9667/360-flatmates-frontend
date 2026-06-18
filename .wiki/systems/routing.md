# Routing

The routing layer is built on `go_router` and lives in `lib/app/router/app_router.dart`. It defines all navigation paths, auth-gated redirects, deep link handling, and mode-dependent tab switching.

## Key abstractions

### GoRouter configuration

**File:** `lib/app/router/app_router.dart`

The router is created as a Riverpod `Provider<GoRouter>` and uses `StatefulShellRoute.indexedStack` for the main tabbed shell with 5 branches:

| Branch | Path | Widget |
|--------|------|--------|
| Home | `/discover` | `DiscoverPage` (with `/discover/browse-listings` child) |
| Tab 2 | `/tab2` | `ModeTab2Switcher` (PostHub or MapView based on mode) |
| Swipe | `/swipe` | `SwipeDeckPage` |
| Chats | `/chats` | `ConversationsPage` (with `/chats/:id` child) |
| Profile | `/profile` | `ProfilePage` (with `/profile/edit`, `/profile/settings`, `/profile/visits` children) |

Full-screen routes use `parentNavigatorKey: _rootNavigatorKey` to render above the shell (e.g., `/flat-details/:id`, `/notifications`, `/schedule-visit`, `/match-celebration`).

### Auth redirect chain

The router's `redirect` function implements a multi-stage gate:

1. **Checking** (`AuthStatus.checking`) -- redirect to `/splash`
2. **Unauthenticated** -- redirect to `/enter-phone`
3. **Needs password** (`auth.needsPassword`) -- redirect to `/set-password` (mandatory after OTP verify for passwordless accounts)
4. **Bootstrap loading** -- redirect to `/splash`
5. **Post-Google add-phone** (`addPhonePromptProvider` + no phone) -- redirect to `/add-phone`
6. **Profile completion gate** (`AuthStage.profileCompletion`) -- redirect to `/profile/edit`
7. **Onboarding incomplete** -- redirect to `/onboarding`
8. **Deep link pending** (`DeepLinkService.consumePendingDeepLink()`) -- redirect to the deep link path
9. **Authenticated + on auth/splash routes** -- redirect to `/discover`

The router refreshes when:
- `authControllerProvider` emits a status change
- `bootstrapControllerProvider` emits data for the first time
- `addPhonePromptProvider` toggles

### Deep links

**File:** `lib/core/deep_links/deep_link_service.dart`

The `DeepLinkService` parses incoming HTTP deep links via the `app_links` package:

| External path | Internal route |
|---|---|
| `/flatmates/listing/{id}` | `/flat-details/{id}` |
| `/flatmates/chat/{id}` | `/chats/{id}` |

The service handles both cold start (`getInitialLink()`) and warm start (`uriLinkStream`). Deep link paths are validated (positive integer IDs, no leading zeros) and stored as `_pendingDeepLinkPath` for the router's redirect chain to consume.

Helper methods build public URLs:
- `DeepLinkService.listingUrl(listingId)` -- `https://the360ghar.com/flatmates/listing/{id}`
- `DeepLinkService.chatUrl(chatId)` -- `https://the360ghar.com/flatmates/chat/{id}`

### ModeTab2Switcher

**File:** `lib/app/router/app_router.dart`

A `ConsumerStatefulWidget` that renders the second bottom nav tab based on the user's mode:

- **Room Poster** -- `PostHubPage` (list property + manage listings)
- **Co-Hunter / Open to Both** -- `MapViewPage` (map-based property discovery)

The mode is read from `bootstrapControllerProvider` via `tab2ModeProvider`. The widget is intentionally kept as a stable wrapper (no `ValueKey` swap) to avoid Semantics tree assertion failures during mode flips.

### RouterRefreshNotifier

A `ChangeNotifier` that the GoRouter listens to. Providers call `refreshNotifier.refresh()` to trigger a re-evaluation of the redirect chain.

## How it works

1. `bootstrap.dart` creates the `App` widget inside a `ProviderScope`
2. `App.build()` reads `appRouterProvider` and passes it to `MaterialApp.router`
3. On each navigation, GoRouter evaluates the redirect chain against current auth and bootstrap state
4. `DeepLinkService.init()` is called in `App.initState()` after the first frame (when GoRouter is available)
5. Incoming deep links are routed via `_router.go(path)`, which triggers the redirect chain

## Integration points

- **Auth:** `authControllerProvider` drives the redirect chain and triggers router refresh
- **Bootstrap:** `bootstrapControllerProvider` provides profile data (mode, onboarding status)
- **Deep links:** `DeepLinkService` stores pending paths for the redirect chain
- **SSE:** `sseEventRouterProvider` is activated in `App.build()` alongside the router
- **Notifications:** `NotificationService.consumePendingRoute()` provides notification-triggered navigation paths

## Key source files

| File | Purpose |
|------|---------|
| `lib/app/router/app_router.dart` | GoRouter config, redirect chain, all route definitions |
| `lib/core/deep_links/deep_link_service.dart` | Deep link parsing and routing |
| `lib/app/app_shell.dart` | Bottom navigation shell (mode-dependent tab visibility) |
| `lib/app/app.dart` | Router initialization, deep link service setup |

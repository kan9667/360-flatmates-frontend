# Lore

A history of the 360 FlatMates codebase, told through its commits.

## Timeline

The project spans from April 24, 2026 to June 18, 2026 -- roughly 8 weeks from initial commit to the current state. 53 commits total.

## Eras

### Era 1: The Baseline (April 24, 2026)

**Commit:** `560f96b` -- *Initial commit: 360 Flatmates Flutter app baseline*

The first commit landed a working Flutter app with the core feature set: auth, onboarding, discover feed, swipe deck, chat, listings, visits, profile, and settings. This was not a skeleton -- it was a fully structured app with Riverpod state management, GoRouter routing, Supabase auth, Dio networking, and a shared component library.

### Era 2: Gap Analysis (Late April -- Early May 2026)

**Commits:** `53a31eb`, `57c76f2`, `0ffa6b5`

A comprehensive gap analysis identified 14 P0, 21 P1, and 10 P2 items. The implementation addressed design system tokens, shared component polish, feature refinements, tests, and QA tooling. This era established the `Flatmates*` widget family and the design token system (`AppSemanticColors`, `AppMotion`, `AppSpacing`, etc.).

### Era 3: Map, Auth, and Feature Polish (May 2026)

**Commits:** `fb333ef`, `767f9e7`, `48a2558`, `bdac932`, `7815742`, `db32439`, `590943d`, `9dc467a`, `4281883`

A burst of feature work:
- Map-list sync with draggable bottom sheet
- Swipe deck actions and polish
- Auth/onboarding refinements
- Chat and feedback controllers
- Removed cert pinner (moved to standard TLS)
- UI mapping improvements

**Commit:** `5843dc5` -- *fix: images not loading, map blank when feed has data, floor plan and virtual tour missing UI*

A notable bugfix pass that addressed image loading failures, a blank map when the feed had data, and missing floor plan / virtual tour UI.

### Era 4: Version Bumps and Platform Config (May 2026)

**Commits:** `5ccaecd`, `27ba872`, `2969faf`, `244dcbb`

- Version bumped to 1.2.0
- Map listing filter logic refined
- Localization updates
- Platform configs and settings page updates

### Era 5: Auth Gate and Polish (Late May 2026)

**Commits:** `e2ac6be`, `19f477c`, `835c05b`

- Centralized auth gate-state model with profile-completion gate
- Discover filters refactored into bottom sheet
- Flatmate/owner profile sheets and like button added
- Dead read-aliases dropped (backend now canonical-only)

### Era 6: Share, Maps, and Release (Late May 2026)

**Commits:** `f841915`, `2df8bad`, `2fc6ca9`, `cbff749`

- "Incorrect password" fix (showed OTP error instead)
- Swipe card enrichment with listing data
- Platform config updates, map widgets, settings polish
- **Release v1.3.0+11**: share/maps/chat/owner-profile fixes, icon consistency

### Era 7: Quality and Format (June 2026)

**Commits:** `d2f259d`, `fe8aa1c`, `33317b4`, `29a7c39`, `210410c`, `b0707e6`, `ed94bc1`

A quality-focused era:
- First-login bounce fix (#9)
- VS Code format-on-save config
- IntelliJ/Android Studio format-on-save config
- Consistent filter icon across all screens
- Dart formatting pass

### Era 8: The Audit (June 2026)

**Commits:** `09055b0` through `68bd3c0`

A systematic feature-by-feature audit, fixing issues across all domains:

| Commit | Area |
|--------|------|
| `09055b0` | Chats |
| `7728bcb` | Discover, map, location |
| `a427644` | Auth, bootstrap |
| `03621f7` | Visits |
| `9685478` | Swipe, match |
| `e7a0804` | Onboarding |
| `70f16b4` | Settings, notifications, feedback |
| `5069818` | Listings |
| `244a38b` | Profile, help, legal |

Then the integration pass (merging audit fixes into the main feature branches):

| Commit | Area |
|--------|------|
| `b9edc6a` | Chats |
| `e20c35d` | Discover |
| `607d058` | Auth |
| `ad4ee6f` | Visits |
| `dd51875` | Swipe |
| `240a77a` | Onboarding |
| `2c512f7` | Settings |
| `f192f40` | Listings |
| `f7f4da1` | Profile |

**Final commit:** `68bd3c0` -- *integrate: unified l10n (49 new EN+HI keys) + regenerated localization*

The audit added 49 new localization keys across English and Hindi, bringing the total to ~800 keys per language.

## Notable decisions

- **No mock repositories.** The app uses real backend APIs exclusively. No hardcoded catalogs or fake payloads.
- **Client-side compatibility scoring.** The matching algorithm runs on-device, not on the server, for instant feedback.
- **SSE over WebSocket.** The realtime event stream uses Server-Sent Events rather than WebSocket, with Supabase realtime as a secondary channel for chat.
- **Single-flight token refresh.** Concurrent 401s share one Supabase refresh RPC, with a request queue that replays after the new token arrives.
- **TransientAuthRefreshException.** A custom exception type that distinguishes "refresh failed due to network" from "no session exists", preventing forced logouts on flaky connections.
- **Mode-dependent tab 2.** The second bottom nav tab shows different content based on user mode (Room Poster sees Post/Manage, Co-Hunter sees Map), using a stable `ModeTab2Switcher` wrapper to avoid Semantics tree assertion failures.
- **Frosted-glass navigation.** The bottom nav bar uses `BackdropFilter` with 3-sigma blur and 0.88 alpha, matching the design system's editorial aesthetic.

## Deprecated or removed features

- **Certificate pinning** -- removed in favor of standard TLS (`bdac932`)
- **Dead read-aliases** -- backend enum aliases dropped when backend moved to canonical-only values (`835c05b`)
- **Alice HTTP inspector** -- commented out due to dependency conflict with `share_plus` ^10.1.4

# Debugging

## Logs and print statements

Use `debugPrint()` for all debug logging in Dart — never `print()`. The `avoid_print` lint rule enforces this. The standard logging pattern includes the class name and method:

```dart
debugPrint('AuthController.checkSession failed: $e');
```

Every `catch` block must log at minimum via `debugPrint`. Empty catch blocks are banned.

## serve-sim (iOS Simulator Browser Preview)

When running on iOS Simulator, serve-sim streams the simulator's framebuffer to a browser at `http://localhost:3200`. This is useful for debugging UI issues visually and for AI agents to test the app:

```bash
npx serve-sim                  # -> http://localhost:3200
flutter run                    # then launch on simulator
```

The stream supports 60fps MJPEG, gesture forwarding, keyboard forwarding, and drag-and-drop media.

## Flutter DevTools

Use Flutter DevTools for widget tree inspection, layout issues, performance profiling, and network logging:

```bash
flutter run --profile
# Then open DevTools: https://docs.flutter.dev/tools/devtools
```

## Common issues

### 401 bounce back to login on startup

The `BootstrapController` was previously fetching `/bootstrap` and `/users/me/auth-state` eagerly at app launch while the user was still unauthenticated. Token-less calls return 401, the auth interceptor clears the session, and the resulting event races with the user's first successful login. **Fix:** `BootstrapController.build()` now gates on `auth.isLoggedIn` — bootstrap is only fetched after a post-login transition with a warm token.

### Semantics parentDataDirty assertion

The `ModeTab2Switcher` widget previously had `ValueKey` on its children, causing `SemanticsNode` detach/attach to race the parent-data flush when the user mode switches. **Fix:** Children are returned without `ValueKeys` — the internal `build()` picks the correct child based on mode, keeping the Element alive across mode flips.

### Navigation destination shape changes

When the user switches mode (room_poster vs co_hunter/open_to_both), the bottom nav destination list was changing shape, causing inner `Semantics` widgets to unmount+remount in the same frame as the tab body swap. **Fix:** The slot is always present (same `NavigationDestination` instance keyed by `nav_mode`), only the icon and label change.

### Localization not updating

Run `flutter gen-l10n` after modifying `.arb` files to regenerate the localization code. Generated files live in `lib/l10n/gen/` and are committed.

### Build runner issues

After changing freezed or json_serializable models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If conflicts persist, use `--delete-conflicting-outputs` and ensure generated files (`.freezed.dart`, `.g.dart`) are committed.

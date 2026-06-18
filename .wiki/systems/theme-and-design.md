# Theme & Design

The theme system implements a warm-editorial design language inspired by ink on paper. It lives under `lib/core/theme/` and is consumed by every screen in the app. The canonical design specification is documented in `DESIGN.md` at the repo root.

## Key abstractions

### AppTheme.build()

**File:** `lib/core/theme/app_theme.dart`

The central factory that produces a complete Material 3 `ThemeData`. It accepts a `Brightness` (light/dark) and an `AppPalette` (color scheme) and wires together all design tokens:

```dart
theme: AppTheme.build(brightness: Brightness.light, palette: settings.palette),
darkTheme: AppTheme.build(brightness: Brightness.dark, palette: settings.palette),
themeMode: settings.themeMode,
```

What it configures:
- **ColorScheme** -- `ColorScheme.fromSeed()` with palette-specific seed color, then overrides for primary, surface, onSurface, outline, error
- **TextTheme** -- Google Fonts (Fraunces for headlines, Inter for body) with exact sizes, weights, line heights, and letter spacing from `AppTypography`
- **Page transitions** -- `FadeUpwardsPageTransitionsBuilder` on Android, `CupertinoPageTransitionsBuilder` on iOS
- **Card theme** -- elevation 1 (light) / 0 (dark), warm shadow tint, 16px radius
- **Dialog theme** -- 8px radius, elevation 4
- **Input decoration** -- filled, 9px radius, terracotta focus border
- **Navigation bar** -- frosted-glass background (0.88 alpha), terracotta indicator, mode-dependent icon colors
- **Button themes** -- filled (terracotta bg, white text), outlined (terracotta border), with terracotta-tinted shadows
- **Snackbar** -- floating, ink background, 16px radius

### AppSemanticColors

**File:** `lib/core/theme/app_semantic_colors.dart`

The canonical color token library. Every color used in the app should reference these constants instead of hardcoded hex values.

**Accent:** `#C96442` (terracotta) -- the primary brand color for CTAs, active states, icons, progress bars.

**Paper scale** (background surfaces):
| Token | Value | Usage |
|-------|-------|-------|
| `paper` | `#F4F3EE` | Scaffold background (warm off-white) |
| `paper2` | `#EDEBE3` | Elevated surfaces, chip backgrounds |
| `paper3` | `#E4E1D7` | Deeper surfaces, muted pills |
| `paper4` | `#D8D4C7` | Deepest shade, disabled fills |
| `card` | `#FFFFFF` | Card backgrounds, input fills |

**Ink scale** (text):
| Token | Value | Usage |
|-------|-------|-------|
| `ink` | `#1F1A14` | Primary text (headlines, titles) |
| `ink2` | `#4A463E` | Secondary text (body, descriptions) |
| `ink3` | `#8A847A` | Tertiary text (timestamps, hints) |
| `ink4` | `#B5AFA3` | Disabled outlines, faint dividers |

**Semantic status colors:** `success` (#5B8C44), `error` (#B4452C), `warning` (#B57828)

**Categorical pastel palette:** 8 categories (blue, purple, green, yellow, orange, teal, pink, coral), each with soft/mid/ink tiers for backgrounds, accents, and text.

**Dark mode overrides:** `darkScaffold` (#1A1612), `darkSurface` (#2A2520), `darkSurfaceElevated` (#342E28). Brightness-aware helpers (`textPrimaryFor()`, `surfaceFor()`, etc.) return the correct token for the current theme.

**Frost/glassmorphism:** `frostOverlayLight`, `frostOverlayDark`, `frostBlur` (3.0 sigma) for frosted-glass surfaces (bottom nav, bottom sheets).

### AppPalette

**File:** `lib/core/theme/app_palette.dart`

An enum of 4 color palettes that the user can switch between:

| Palette | Seed Color | Label |
|---------|-----------|-------|
| `inkOnPaper` | `#C96442` (terracotta) | "Ink on Paper" (default) |
| `electricIndigo` | `#5B88B5` (blue) | "Paper Blue" |
| `emberCoral` | `#D17847` (orange) | "Warm Clay" |
| `monsoonTeal` | `#5A9DA8` (teal) | "Monsoon Teal" |

Palette selection is persisted to `SharedPreferences` and applied via `AppTheme.build(brightness:, palette:)`.

### AppMotion

**File:** `lib/core/theme/app_motion.dart`

Canonical animation duration and curve tokens. All animations in the app reference these constants.

**Named durations:** `fast` (150ms), `standard` (220ms), `slow` (300ms). Specific durations: `chipSelect`, `segmentTransition`, `pageTransition` (250ms), `tabSwitch` (200ms), `buttonPress`, `cardAppear`, `cardStagger` (50ms), `compatibilityRing`, `matchCelebration` (600ms), `bottomSheet` (280ms), `fabExpand` (250ms), `skeletonShimmer` (1200ms), `heroTransition` (300ms), `fadeInEntry` (200ms), `staggerItem` (100ms), `breathing` (2s).

**Curves:** `easeOutCubic`, `easeOutQuart`, `easeOutExpo`, `easeOutBack` (slight overshoot for FAB only).

**Utilities:** `reduceMotion(context)` checks `MediaQuery.disableAnimationsOf`, `durationOrZero()` returns zero duration when reduced motion is active, `staggerInterval()` computes `Interval` for staggered list animations.

## Design token files

All token files are barrel-exported via `lib/core/theme/theme.dart`:

| File | Tokens |
|------|--------|
| `app_semantic_colors.dart` | All color constants (accent, paper, ink, line, status, categorical, dark mode) |
| `app_palette.dart` | Palette enum with seed colors |
| `app_typography.dart` | Font families, sizes, weights, line heights, letter spacing |
| `app_spacing.dart` | Spacing scale (xs=4, sm=8, md=12, lg=16, xl=20, screen=24, section=28) |
| `app_radius.dart` | Border radius tokens (sm=9, md=10, card=16, sheet=8, pill=999) |
| `app_shadows.dart` | Shadow tokens with light/dark variants (card, button, floating, modal, subtleGlow, cardHover, bottomBar, inputFocusGlow) |
| `app_gradients.dart` | Gradient tokens (primary, surface, shimmer, success/warning/error, nudge, 8 category gradients) |
| `app_motion.dart` | Duration and curve tokens |
| `app_theme.dart` | `AppTheme.build()` factory |

## How it works

1. User selects a palette and theme mode in Settings; these are persisted via `AppPreferences`
2. `App.build()` reads `settingsControllerProvider` for the current palette and theme mode
3. `AppTheme.build()` is called twice (light and dark themes) and passed to `MaterialApp.router`
4. Widgets access tokens via `Theme.of(context)` or import the token files directly for constants
5. Shared components (`Flatmates*` widgets) use these tokens internally for consistent styling

## Key source files

| File | Purpose |
|------|---------|
| `lib/core/theme/app_theme.dart` | Material 3 ThemeData factory |
| `lib/core/theme/app_semantic_colors.dart` | All color tokens |
| `lib/core/theme/app_palette.dart` | User-selectable color palettes |
| `lib/core/theme/app_typography.dart` | Type scale constants |
| `lib/core/theme/app_motion.dart` | Animation duration/curve tokens |
| `lib/core/theme/app_spacing.dart` | Spacing tokens |
| `lib/core/theme/app_radius.dart` | Border radius tokens |
| `lib/core/theme/app_shadows.dart` | Shadow tokens |
| `lib/core/theme/app_gradients.dart` | Gradient tokens |
| `lib/core/theme/theme.dart` | Barrel export |
| `DESIGN.md` | Canonical design specification |

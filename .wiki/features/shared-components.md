# Shared Components

**Active contributors:** Saksham Mittal, Ravi Sahu

## Purpose

The shared components library provides 24 reusable Flutter widgets that enforce design system consistency across the app. All pages should import `components.dart` and use `Flatmates*` widgets instead of duplicating Scaffold, SafeArea, ListView, or async-state patterns.

## Directory Layout

```
lib/features/shared/presentation/
├── components.dart                    # Barrel export for all shared widgets
├── app_icons.dart                     # Custom icon constants
├── flatmates_async_view.dart          # Async state handler
├── flatmates_bottom_action_bar.dart   # Sticky bottom CTA bar
├── flatmates_bottom_sheet.dart        # Frosted-glass bottom sheet
├── flatmates_card.dart                # Interactive card with press glow
├── flatmates_chip.dart                # Filter/choice/info/removable chip
├── flatmates_empty_state.dart         # Empty state with breathing icon
├── flatmates_error_state.dart         # Error state with retry
├── flatmates_header.dart              # Page header with logo/back/actions
├── flatmates_like_button.dart         # Animated like button
├── flatmates_listing_mini_card.dart   # Compact listing row
├── flatmates_network_image.dart       # Network image with fallback
├── flatmates_otp_input.dart           # OTP input field
├── flatmates_price_text.dart          # Formatted price display
├── flatmates_profile_mini_card.dart   # Compact profile row
├── flatmates_screen.dart              # Unified page scaffold
├── flatmates_search_bar.dart          # Search input with focus glow
├── flatmates_segmented_control.dart   # Tab-style selector with sliding pill
├── flatmates_skeleton.dart            # Shimmer loading placeholders
├── flatmates_step_progress.dart       # Multi-step progress indicator
├── flatmates_toast.dart               # Toast notifications
├── flatmates_trust_badge.dart         # Verified/privacy/reviewed badges
├── flatmates_ui.dart                  # Additional UI primitives
└── flatmates_video_tour_player.dart   # Video tour player
```

## Widget Inventory

| Widget | Purpose | Key Features |
|--------|---------|--------------|
| `FlatmatesScreen` | Unified page scaffold | Scaffold + SafeArea + 200ms fade-in entry, paper background |
| `FlatmatesAsyncView` | Async state handler | Renders loading/data/empty/error from `AsyncValue<T>` |
| `FlatmatesNetworkImage` | Network image with fallback | Placeholder + error state, replaces raw `Image.network` |
| `FlatmatesCard` | Content card container | Interactive press glow (0.97 scale), optional gradient/borderGlow |
| `FlatmatesChip` | Filter/tag chip | `.choice()` variant with selection spring (1.03 scale, easeOutBack) |
| `FlatmatesHeader` | Page header | `.logo()`, `.backTitle()`, `.backOnly()` variants |
| `FlatmatesSkeleton` | Shimmer loading placeholder | `.card()`, `.list()`, `.feed()`, `.profile()`, `.notificationList()`, `.visitList()`, `.manageListings()` |
| `FlatmatesErrorState` | Error display with retry | 200ms fade-in + slide-up entry |
| `FlatmatesEmptyState` | Empty state with illustration | 200ms fade-in + breathing icon (2s pulse) |
| `FlatmatesBottomActionBar` | Sticky bottom CTA bar | Frosted-glass backdrop, primary + optional secondary button |
| `FlatmatesBottomSheet` | Styled bottom sheet | Frosted-glass backdrop via `BackdropFilter` + `ClipRRect` |
| `FlatmatesSearchBar` | Search input | Focus glow (terracotta shadow) + 1.01 scale lift |
| `FlatmatesSegmentedControl` | Tab-style selector | `AnimatedPositioned` sliding pill indicator (220ms) |
| `FlatmatesStepProgress` | Multi-step progress | Thin progress bar with step dots |
| `FlatmatesPriceText` | Formatted price display | Rupee formatting with locale awareness |
| `FlatmatesTrustBadge` | Trust indicator badge | `.verified`, `.reviewed`, `.privacy`, `.safe` variants |
| `FlatmatesProfileMiniCard` | Compact profile row | Avatar + name + subtitle |
| `FlatmatesListingMiniCard` | Compact listing row | Thumbnail + title + price |
| `FlatmatesToast` | Toast notifications | `.success()`, `.error()`, `.info()` variants |
| `FlatmatesButton` | Button variants | `.primary()`, `.secondary()`, `.tertiary()` with press feedback |
| `FlatmatesAvatar` | Avatar with ring | Animated arc-draw on mount (300ms), `showRing` parameter |
| `FlatmatesLikeButton` | Animated like button | Heart animation on tap |
| `FlatmatesMenuItem` | Menu item row | Icon container + label + chevron, 56px height |
| `FlatmatesNotificationCard` | Notification card | Type-based icon/color, unread indicator |

## Key Patterns

### Press Feedback

All interactive cards, buttons, and menu items use `Listener` + `AnimatedScale` (not `GestureDetector`) for press detection:

```dart
Listener(
  onPointerDown: (_) => setState(() => _scale = 0.97),
  onPointerUp: (_) => setState(() => _scale = 1.0),
  onPointerCancel: (_) => setState(() => _scale = 1.0),
  child: AnimatedScale(
    scale: _scale,
    duration: AppMotion.buttonPress,  // 150ms
    curve: AppMotion.easeOutCubic,
    child: widget.child,
  ),
)
```

This avoids gesture arena conflicts when wrapping interactive children like `InkWell` or `FilledButton`.

### Frosted Glass

Bottom navigation, bottom sheets, and bottom action bars use:

```dart
ClipRRect(
  borderRadius: AppRadius.sheetTopBorder,
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
    child: Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.88),
        borderRadius: AppRadius.sheetTopBorder,
      ),
      // ... content
    ),
  ),
)
```

The `ClipRRect` before `BackdropFilter` constrains blur bounds. Alpha values: 0.88 for nav/action bars, 0.92 for bottom sheets.

### Animated Rings

Compatibility rings and avatar rings draw their arc on mount via `CustomPaint` inside `AnimatedBuilder`:

- Duration: 300ms
- Curve: ease-out
- Used by `FlatmatesAvatar(showRing: true)` and profile grid match circles

### Staggered Appear

Feed cards and menu groups use staggered fade-in + slide-up animations:

- Feed cards: `StaggeredCardAppear` with 50ms stagger between items
- Menu groups: `Future.delayed` with 100ms delay between groups, 300ms base delay
- Duration: 200ms per item, easeOutCubic curve

### Skeleton Loading

`FlatmatesSkeleton` provides named constructors for different loading patterns:

- `.card()` -- single card placeholder
- `.list()` -- vertical list of card placeholders
- `.feed()` -- horizontal scroll feed placeholder
- `.profile()` -- profile page layout placeholder
- `.notificationList()` -- notification card list
- `.visitList()` -- visit card list
- `.manageListings()` -- manage listings layout

All skeletons use a 1200ms linear shimmer gradient animation.

### Entry Animations

`FlatmatesEmptyState` and `FlatmatesErrorState` fade in + slide up on mount (200ms). Empty-state icons have a subtle 2s breathing (pulse) animation.

## Integration Points

- **Design Tokens** -- all widgets use `AppMotion`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppSemanticColors`, and `AppTypography` from `core/theme/`.
- **Localization** -- all user-facing strings use `AppLocalizations.of(context)`.
- **Dark Mode** -- all widgets resolve colors based on `theme.brightness` using `AppSemanticColors` helpers.

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/features/shared/presentation/components.dart` | Barrel export for all shared widgets |
| `lib/features/shared/presentation/flatmates_screen.dart` | Unified page scaffold with fade-in |
| `lib/features/shared/presentation/flatmates_card.dart` | Interactive card with press glow |
| `lib/features/shared/presentation/flatmates_chip.dart` | Chip variants with selection spring |
| `lib/features/shared/presentation/flatmates_skeleton.dart` | Shimmer loading placeholders |
| `lib/features/shared/presentation/flatmates_bottom_action_bar.dart` | Frosted-glass CTA bar |
| `lib/features/shared/presentation/flatmates_segmented_control.dart` | Sliding pill selector |
| `lib/core/theme/` | Design token constants |

# Profile Feature

**Active contributors:** Saksham Mittal, Ravi Sahu

## Purpose

The profile feature displays the user's profile with avatar, menu items for key app sections, a profile strength indicator, and an edit profile flow. It serves as the primary account management entry point.

## Directory Layout

```
lib/features/profile/
├── profile_page.dart                  # Profile view with menu items
├── edit_profile_page.dart             # Full profile edit form
├── profile_repository.dart            # API client for profile CRUD
└── presentation/widgets/
    ├── edit_profile_options.dart       # Catalog-driven option lists
    └── edit_profile_sections.dart      # Edit form section widgets
```

## Key Abstractions

- **`ProfileRepository`** -- Riverpod provider wrapping Dio calls for `GET` and `PUT` on `/api/v1/flatmates/profile`.
- **`FlatmatesProfileModel`** -- domain model for user profile data (defined in bootstrap, includes name, age, profession, city, locality, mode, preferences, bio, lifestyle fields).
- **`BootstrapController`** -- provides the profile data as part of the bootstrap payload; refreshed after profile updates.

## How It Works

### Profile Page

`ProfilePage` is a `ConsumerWidget` that watches `bootstrapControllerProvider` and renders:

1. **Compact header** -- avatar (80px, with animated ring on mount) on the left, name/email/phone and location on the right. An edit FAB overlay (terracotta circle) sits at the bottom-right of the avatar.
2. **Profile strength card** -- circular progress indicator showing completion percentage based on 10 checks (name, photo, city, locality, mode, budget, timeline, bio, cleanliness, food habits). Tapping navigates to edit profile.
3. **Menu groups** with staggered fade-in animation:
   - **Discovery** -- Post/Manage Listings, Visits, Shortlisted, Chats
   - **Trust** -- Documents
   - **Account** -- Settings, Help & Safety
4. **Logout** -- tertiary destructive button that calls `AuthController.signOut()`

### Profile Strength Calculation

The strength percentage is computed by checking 10 profile fields:
- `fullName`, `profileImageUrl`, `city`, `locality`, `mode`, `budgetMin`+`budgetMax`, `moveInTimeline`, `bio`, `cleanliness`, `foodHabits`

Each non-empty field contributes 10% to the total.

### Edit Profile Page

`EditProfilePage` is a `ConsumerStatefulWidget` with extensive form sections:

1. **Photo** -- upload via `ImageUploadService.uploadProfilePhoto()`, stored in `_photoUrlsProvider`
2. **Contact info** -- email and phone (only editable if not already set)
3. **Basic info** -- name, age, profession, city, locality
4. **Mode** -- room poster, co-hunter, or open to both
5. **Budget & timeline** -- min/max budget, move-in timeline, work style
6. **Lifestyle** -- sleep schedule, cleanliness, food habits, smoking/drinking, guests policy
7. **Non-negotiables** -- multi-select chips from catalog options
8. **Bio** -- free-text bio field

All local UI state uses file-level `StateProvider` instances (no `setState` in `ConsumerState`). The form tracks `_dirtyProvider` and shows an unsaved-changes confirmation dialog on back navigation.

### Save Flow

On save:
1. Validates budget range (min <= max)
2. Constructs a payload map with all form values
3. Calls `ProfileRepository.updateProfile()` via `PUT /api/v1/flatmates/profile`
4. Refreshes `BootstrapController` to update the global profile state
5. Shows success toast and navigates back

## Integration Points

- **Bootstrap** -- profile data is loaded from the bootstrap endpoint and cached in `BootstrapController`. After updates, the bootstrap is refreshed.
- **Image Upload** -- profile photos use `ImageUploadService.uploadProfilePhoto()` which delegates to Cloudinary via the backend.
- **Catalogs** -- lifestyle options (sleep schedule, cleanliness, food habits, etc.) are resolved from catalog options fetched during bootstrap.
- **Auth** -- logout delegates to `AuthController.signOut()` which clears tokens and redirects to the phone entry screen.

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/features/profile/profile_page.dart` | Profile view with avatar, strength card, menu groups |
| `lib/features/profile/edit_profile_page.dart` | Full profile edit form with 8 sections |
| `lib/features/profile/profile_repository.dart` | API client for profile GET/PUT |
| `lib/features/profile/presentation/widgets/edit_profile_sections.dart` | Edit form section widgets |
| `lib/features/profile/presentation/widgets/edit_profile_options.dart` | Catalog-driven option lists |
| `lib/features/bootstrap/bootstrap_controller.dart` | Profile data source and refresh |

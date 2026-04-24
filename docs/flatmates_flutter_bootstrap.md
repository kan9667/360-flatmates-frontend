# 360 FlatMates Flutter Bootstrap Guide

## Objective

This repository is the dedicated Flutter mobile client for 360 FlatMates. It is intentionally separate from the older 360 Ghar app so the architecture can remain feature-first, Riverpod-based, and focused on the flatmates product.

## Foundation Decisions

- Start from a fresh Flutter app scaffold
- Mobile only in the first bootstrap pass
- Riverpod as the state and dependency backbone
- GoRouter for navigation and guarded route flow
- Supabase for direct auth handling
- FastAPI as the data API for all product capabilities
- Shared preferences for local UX state
- Secure storage for auth token persistence
- Dio as the single network client

## Folder Structure

The implementation uses a feature-first layout with thin shared core modules.

- `lib/app`
- `lib/core`
- `lib/l10n`
- `lib/features/auth`
- `lib/features/bootstrap`
- `lib/features/discover`
- `lib/features/chats`
- `lib/features/visits`
- `lib/features/profile`
- `lib/features/settings`

Shared platform concerns live in `core`. Product behavior lives in `features`.

## Bootstrap Sequence

The runtime boot order is:

1. Ensure Flutter bindings are ready
2. Load `.env`
3. Resolve app configuration
4. Initialize Supabase
5. Initialize shared preferences and secure storage
6. Start the Riverpod app
7. Restore auth state
8. Load the FlatMates bootstrap payload

This keeps the app aligned with the backend from the first frame after authentication.

## Navigation Model

The app uses a guarded router with an indexed shell once the user is authenticated.

- Splash
- Enter phone
- Login
- Signup
- OTP
- Discover
- Chats
- Visits
- Profile
- Edit profile
- Chat thread

The splash route remains the loading and retry surface for backend bootstrap.

## Theme and Locale

Theme is a persisted user preference with two dimensions:

- Theme mode: light, dark, or system
- Palette: multiple brand palettes under the selected brightness

Locale is also persisted and currently supports:

- English
- Hindi

Both settings are available in the profile and settings surface and do not depend on a server round-trip.

## Current API Consumption

The Flutter app currently calls:

- `/api/v1/users/me` for post-auth verification
- `/api/v1/flatmates/bootstrap`
- `/api/v1/flatmates/profile`
- `/api/v1/flatmates/swipes`
- `/api/v1/flatmates/conversations`
- `/api/v1/flatmates/conversations/{id}/messages`
- `/api/v1/visits`
- `/api/v1/properties`

This ensures the app only works with real backend contracts and avoids any local mock repository pattern.

## QA and Iteration Flow

Primary local iteration should happen on iOS Simulator. Android should still receive smoke verification for every milestone because the product is intentionally cross-platform from the start.

The Maestro flow in this repository assumes:

- A seeded Supabase user exists for login
- At least one flatmate listing is available from the backend
- A listing-like creates a usable conversation

## Immediate Next Build Steps

The foundation is intentionally ready for extension rather than exhaustive feature completion. The next recommended app milestones are:

- Richer onboarding and compatibility entry
- Swipe deck presentation for listing and person cards
- Match surfaces for reciprocal profile likes
- Push notifications
- Chat media attachments
- Deeper visit lifecycle UX

# 360 FlatMates Technical Specification

## Product Alignment

360 FlatMates is implemented as a new Flutter mobile client backed by the existing 360 Ghar FastAPI monolith. The mobile app uses Supabase directly for authentication and uses the FastAPI backend as the application system of record for flatmate profile data, listings, swipes, conversations, and visits.

The product source remains `docs/prd.md`, but the implementation architecture in this document replaces the older Firebase and Firestore assumptions.

## Backend Reuse Strategy

The backend reuses existing shared platform entities wherever possible.

- `users` is the primary flatmate profile record.
- `properties` is the flatmate room and PG listing record.
- `user_swipes` is extended to support both property swipes and person swipes.
- `visits` is extended to support flatmate meet requests without introducing a second visit resource.
- Existing Supabase bearer-token auth, upload infrastructure, notification infrastructure, and websocket infrastructure remain part of the monolith.

The only new persistence layer introduced is the reusable social layer that did not already exist in the monolith.

- `user_matches`
- `user_conversations`
- `user_messages`
- `user_blocks`
- `user_reports`
- `app_catalogs`

These tables are generic shared primitives rather than FlatMates-only clones, so they can serve additional peer-to-peer use cases later.

## Data Model Extensions

The `users` table now stores flatmate-specific search and lifecycle fields directly.

- Mode
- Profile status
- Onboarding completion
- Bio
- Budget range
- Move-in timeline
- City and locality
- The six compatibility dimensions from the PRD
- Last active timestamp

The `users.preferences` JSON document remains the long-tail storage area for flatmate-specific metadata that should not be promoted to first-class columns yet.

The `properties` table continues to represent room listings. Flatmate listings are identified through the existing `property_type` and `purpose` values already present in the backend.

The `user_swipes` table now supports both listing and profile actions.

- Listing swipe uses `target_type=property` and `property_id`
- Profile swipe uses `target_type=user` and `target_user_id`
- `swipe_action` preserves pass, like, and super-like
- `context_property_id` allows person-to-person actions to retain listing context

The `visits` table now supports two contexts.

- `property_tour` for existing real-estate visits
- `flatmate_meet` for in-chat flatmate meet requests

Flatmate visits also carry the counterparty user and optional conversation and match linkage so the existing visits resource can support both product surfaces.

## API Surface

The backend now exposes a dedicated FlatMates app surface under `/api/v1/flatmates`.

- `GET /flatmates/bootstrap`
- `GET /flatmates/catalogs`
- `GET /flatmates/profile`
- `PUT /flatmates/profile`
- `POST /flatmates/swipes`
- `GET /flatmates/conversations`
- `GET /flatmates/conversations/{id}/messages`
- `POST /flatmates/conversations/{id}/messages`
- `GET /flatmates/matches`
- `POST /flatmates/blocks`
- `POST /flatmates/reports`

The existing `/api/v1/visits` resource is extended rather than duplicated. It now accepts and returns the flatmate visit context fields alongside the original property-tour behavior.

The Flutter app currently reuses the existing `/api/v1/properties` endpoint for room discovery, filtered to flatmate inventory.

## Chat and Match Behavior

Chat is implemented as a generic two-user conversation layer.

- Profile swipes remain person-to-person
- Reciprocal positive profile swipes create `user_matches`
- Listing likes do not wait for reciprocity and directly create or reuse a conversation with the listing owner
- Only one active conversation is maintained per user pair
- Repeated listing interest from the same pair reuses the existing conversation and updates its listing context

This satisfies the product requirement that flatmate conversations be built on a reusable chat primitive instead of a dedicated FlatMates-only chat schema.

## Catalog Strategy

Business catalogs are served from the backend through `app_catalogs`. Seeded V1 catalogs include:

- Flatmate modes
- Move-in timelines
- Onboarding quiz dimensions
- Vibe tags
- Report reasons

This removes the need for the Flutter app to hardcode business metadata.

## Flutter Architecture

The Flutter application starts from a clean mobile-only scaffold and uses:

- Riverpod for dependency injection and state
- GoRouter for navigation
- Dio for FastAPI communication
- Supabase Flutter for auth
- Shared preferences for theme, palette, and locale persistence
- Secure storage for token persistence
- ARB-based localization for English and Hindi

The app shell currently includes:

- Authentication
- Bootstrap loading
- Discover
- Chats
- Visits
- Profile and settings

Theming supports light, dark, and system modes along with multiple palette presets. Localization currently supports English and Hindi only.

## Current Delivery State

This implementation establishes the platform foundation, the first usable product loop, and the core feature surface:

- Password and OTP auth
- Backend bootstrap
- Full onboarding flow (splash screens, mode selection, basic info, photo upload, lifestyle quiz, budget/timeline, non-negotiables)
- Compatibility engine (6-dimension scoring with animated ring)
- Swipe deck (collapsed/expanded cards, action bar, user-to-user swipes)
- Match celebration screen with Q&A nudge
- Flatmate profile editing
- Listing discovery through real property APIs
- Listing-like to chat creation
- Two-user conversations with photo sharing, icebreaker chips, read receipts, and report/block/unmatch
- Flatmate visit request, confirmation, reschedule, and cancellation
- 6-step listing builder (location, society, room, flat, costs, about)
- Manage listing page with status badges, share, and boost
- Map view with clustered pins and filter bar
- Home feed with vibe filter chips, city counter, and Picked for You
- WhatsApp share card via share_plus
- Waitlist mode for low-density cities
- Privacy settings (hide last name, hide exact location)
- Push notification service (FCM token management)
- 401 auth interceptor with token refresh retry
- Image upload service (camera/gallery + Supabase Storage)
- Theme, palette, and locale switching
- EN + HI localization (150+ strings)

## Immediate Follow-On Work

The next backend and mobile milestones should focus on:

- Real-time chat via WebSocket or polling
- Pagination on listings, conversations, and messages
- AI pre-screening cloud function for listing review
- Seed data for complete end-to-end QA scenarios
- Q&A answer storage backend (match_qa_answers table)
- Geocoding integration for accurate map pin positions
- Google Calendar sync for confirmed visits
- Maestro end-to-end test flow
- App store metadata (icons, screenshots, copy)
- Analytics and crash reporting (Firebase Analytics / Sentry)
- Video tour upload with size/duration enforcement
- Freemium hooks (super like cap, swipe counter, boost slot)
- Broader seed data coverage for QA and Maestro

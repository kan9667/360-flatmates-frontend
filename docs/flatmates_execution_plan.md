# 360 FlatMates Execution Plan

## Current State

The first implementation pass is complete for the shared backend extensions and the Flutter app foundation. The backend now exposes the core FlatMates API surface and the Flutter app is wired to real auth and API contracts.

## Delivery Order

### Phase 1: Platform Foundations

- Extend the FastAPI monolith instead of creating a new service
- Reuse `users`, `properties`, `user_swipes`, and `visits`
- Add generic social tables for matches, conversations, messages, blocks, reports, and catalogs
- Scaffold the new Flutter app
- Wire Supabase auth, env loading, router guards, theme, palette, and localization

### Phase 2: First Product Loop

- Load bootstrap from the backend
- Edit flatmate profile fields
- Discover flatmate listings through real property APIs
- Create conversation threads from listing likes
- Send chat messages
- Schedule flatmate visits through the extended visits resource

### Phase 3: Product Completion

- Build the full swipe deck experience
- Add reciprocal profile-like surfaces and match inbox states
- Add admin moderation in the existing React admin dashboard
- Add push notifications and richer media support
- Expand seeded QA data and Maestro coverage

## Cross-Repo Responsibilities

### `../backend`

- Owns shared schema extensions and new social primitives
- Owns all FlatMates API contracts
- Owns seeded catalogs and flatmate business metadata
- Owns the visit extension logic

### `360-flatmates`

- Owns the mobile user experience
- Owns local theme and locale preferences
- Owns navigation, state composition, and platform polish
- Owns Maestro automation for the mobile flow

### `../real-estate-admin-dashboard`

- Should receive the moderation queue, reports list, and review actions in the next milestone
- Does not need a new service boundary

## Exit Criteria For The Next Milestone

The next milestone should be considered complete only when all of the following are true:

- The backend can seed at least one complete end-to-end flatmates QA scenario
- The app can complete profile setup without manual API workarounds
- A user can like a listing, open the resulting conversation, send a message, and schedule a visit
- The admin dashboard can review flatmate reports and pending profiles or listings
- Maestro can execute the seeded end-to-end flow reliably on iOS Simulator

# Features

Active contributors: Saksham Mittal, Ravi Sahu

This directory documents every feature module in the 360 FlatMates Flutter app. Each feature lives under `lib/features/<name>/` and follows the layered architecture pattern (data / domain / application / presentation).

| Feature | Description |
|---------|-------------|
| [Auth](auth.md) | Authentication flows: phone OTP, email OTP, password login, Google, Apple, account deletion, password reset. |
| [Bootstrap](bootstrap.md) | App-startup data loader that fetches the user profile, catalogs, and auth gate stage in a single parallel call. |
| [Onboarding](onboarding.md) | Multi-step signup wizard: mode selection, location, basic info, photos, lifestyle quiz, budget, preferences, non-negotiables. |
| [Discover](discover.md) | Home feed with paginated listing cards, filter chips, search, map view, flat details, and optimistic likes. |
| [Swipe](swipe.md) | Tinder-style card deck for browsing flatmate profiles with like/pass gestures, compatibility rings, and match celebrations. |
| [Chats](chats.md) | Conversations list, real-time chat threads, incoming/outgoing likes, match actions, block/report, and Q&A nudges. |
| [Listings](listings.md) | Multi-step listing creation wizard, draft persistence, photo/video upload, listing under review, and manage listings dashboard. |
| [Visits](visits.md) | Visit scheduling with calendar picker and time slots, visit list with status management. |
| [Notifications](notifications.md) | In-app notification list with type-based icons, unread indicators, and SSE-driven real-time updates. |
| [Profile](profile.md) | Profile view with avatar edit, personal info, menu-driven navigation, help & support, and legal pages. |
| [Settings](settings.md) | Theme mode, palette, locale switching, notification toggles, password change, privacy, blocked users, account deletion. |
| [Shared components](shared-components.md) | 18+ Flatmates* reusable widget library with premium motion behaviors. |
| [Location](location.md) | Location picker modal, location search, Google Places + Nominatim integration. |
| [Feedback](feedback.md) | In-app bug report and feature request form. |

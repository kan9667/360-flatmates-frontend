# AGENTS.md

## Repo Purpose

This repository contains the dedicated Flutter mobile client for 360 FlatMates. It is not a general-purpose 360 Ghar client and it must stay aligned to the backend monolith and the flatmates-specific app surface.

## Core Rules

- Use real backend APIs only. Do not introduce mock repositories, fake payloads, or hardcoded business catalogs.
- Keep the app mobile-first and maintain parity between iOS and Android.
- Treat `../backend` as the source of truth for product data contracts.
- Keep business metadata server-driven through `/api/v1/flatmates/catalogs` whenever the data affects product behavior.

## Architecture Boundaries

- `lib/core` is for app-wide technical plumbing only.
- `lib/features` owns product behavior and presentation.
- Avoid leaking feature logic into `core`.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.

## Riverpod Guidance

- Prefer Riverpod providers over singleton services.
- Keep async fetching in providers or focused notifiers.
- Invalidate feature providers after write operations instead of manually syncing widget trees.
- Avoid global mutable state outside provider-controlled objects.

## Networking Guidance

- Use the shared Dio client from `core`.
- All authenticated requests must flow through the shared auth interceptor.
- Do not bypass the shared client for ad hoc HTTP calls.
- Keep backend paths centralized by usage, not by hardcoded duplication of base URLs.

## UI Guidance

- Maintain support for light, dark, and system theme modes.
- Preserve palette switching as a first-class product capability.
- Keep English and Hindi localization coverage in sync for all primary user flows.
- Use meaningful keys on major interactive widgets so Maestro coverage can remain stable.

## Testing Guidance

- Keep `flutter analyze` clean.
- Keep at least one fast local Flutter test in the repo.
- Maintain a single end-to-end Maestro flow that exercises the real product loop.
- Update Maestro when route names, button labels, or login flow behavior changes.

## Documentation Triggers

Update the docs in `docs/` when any of the following change:

- Backend API surface consumed by the app
- Repo architecture or folder layout
- Theme and localization strategy
- Auth bootstrap flow
- Maestro prerequisites or seeded-data assumptions

## Cross-Repo Discipline

- If a change requires new backend fields or endpoints, implement or coordinate that work in `../backend`.
- If moderation or review workflows are required, plan or implement them in `../real-estate-admin-dashboard`.
- Do not fork the contract locally in the Flutter app to avoid touching the backend.

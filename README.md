# 360 FlatMates

Flutter mobile client for the 360 FlatMates product.

## Setup

1. Copy `.env.example` to `.env` and fill the Supabase and backend values.
2. Run `flutter pub get`.
3. Start the backend monolith from `../backend`.
4. Run `flutter run`.

## Quality Checks

- `flutter analyze`
- `flutter test`

## Backend Dependency

This app expects the FlatMates API surface to exist in the shared FastAPI monolith at `../backend`.

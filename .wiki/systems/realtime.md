# Realtime

The realtime system keeps the app in sync with backend state changes without polling. It combines two complementary channels: a custom Server-Sent Events (SSE) stream for app-level events, and Supabase realtime subscriptions for chat message delivery.

## Key abstractions

### SseService

**File:** `lib/core/network/sse_service.dart`

Manages a long-lived SSE connection to `GET /flatmates/sse`. The service handles connection lifecycle, line-by-line SSE parsing, automatic reconnection with exponential backoff (1s to 30s), and graceful disconnect on logout.

**Lifecycle:**
- `connect(baseUrl, tokenRefresher)` -- opens (or reopens) the connection. The `tokenRefresher` callback is called before every connection attempt so the JWT is never stale.
- `disconnect()` -- tears down the connection gracefully; no automatic reconnect.
- `dispose()` -- permanently shuts down the service.

**Parsing:** The service reads the HTTP response stream line by line, buffers `data:` fields, and emits `SseEvent` objects (with `type` and `data` map) when it encounters an empty line (SSE event boundary).

**Reconnection:** On connection loss (non-intentional), the service schedules a reconnect with doubling delay, clamped at 30 seconds. The delay resets to 1 second after a successful connection.

### sseEventRouterProvider

**File:** `lib/core/network/sse_providers.dart`

A Riverpod `Provider<void>` that watches the SSE event stream and invalidates the relevant feature providers based on event type:

| SSE Event Type | Invalidated Providers |
|---|---|
| `new_match` | `conversationsProvider`, `incomingLikesProvider`, `outgoingLikesProvider` |
| `new_like` / `incoming_like` | `incomingLikesProvider`, `outgoingLikesProvider` |
| `new_notification` | `notificationsProvider` |
| `visit_updated` | `visitsProvider` |

This provider is activated in `App.build()` via `ref.watch(sseEventRouterProvider)`.

### Supabase Realtime for Chat

**File:** `lib/features/chats/chats_repository.dart`

The `conversationsRealtimeProvider` creates a Supabase realtime subscription on the `user_messages` table, filtered by `conversation_id`. When new messages arrive (inserts, updates, read-status changes), the stream emits and the `messagesStreamProvider` / `conversationsProvider` are refreshed.

The `MessagesController` (a `FamilyNotifier` per conversation) merges:
1. Live arrivals from `messagesStreamProvider` (Supabase realtime)
2. Optimistic pending sends (negative IDs)
3. Authoritative HTTP refetch after a successful POST

This three-way merge ensures messages persist even when realtime is temporarily unavailable.

## How it works

1. On login, `App._AppState` connects the SSE service with the current base URL and a token refresher callback
2. `sseEventRouterProvider` activates the SSE stream and the Supabase realtime watcher
3. Incoming SSE events trigger `ref.invalidate()` on the relevant providers
4. Supabase realtime events trigger conversation/message provider refreshes
5. On logout, both the SSE connection and Supabase subscriptions are torn down

```
Backend          SSE Stream              Riverpod Providers
  |                  |                         |
  |-- event -------->|                         |
  |                  |-- sseEventRouter -------->|
  |                  |   (invalidate providers) |
  |                  |                         |-- UI rebuilds
  |                  |                         |
  |-- DB insert ---->| (Supabase realtime)     |
  |                  |-- messagesStreamProvider->|
  |                  |                         |-- Chat UI rebuilds
```

## Integration points

- **SSE endpoint:** `GET /flatmates/sse` (defined in `FlatmatesEndpoints.sse`)
- **Supabase:** `user_messages` table for realtime chat subscriptions
- **Riverpod invalidation:** `conversationsProvider`, `incomingLikesProvider`, `outgoingLikesProvider`, `notificationsProvider`, `visitsProvider`
- **Auth:** Both channels require a valid JWT; SSE calls `tokenRefresher` on each reconnect

## Key source files

| File | Purpose |
|------|---------|
| `lib/core/network/sse_service.dart` | SSE connection, parsing, reconnect logic |
| `lib/core/network/sse_providers.dart` | SSE event stream + invalidation router |
| `lib/features/chats/chats_repository.dart` | Supabase realtime subscription for chat messages |
| `lib/app/app.dart` | SSE connect/disconnect on auth state changes |

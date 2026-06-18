# Notifications Feature

**Active contributors:** Saksham Mittal, Ravi Sahu

## Purpose

The notifications feature displays a list of in-app notifications with type-based icons and colors, unread indicators, and tap-to-navigate behavior. It supports marking individual or all notifications as read.

## Directory Layout

```
lib/features/notifications/
├── notifications_page.dart            # Notification list UI
└── notifications_repository.dart      # API client for notifications
```

## Key Abstractions

- **`NotificationModel`** -- domain model with id, title, body, type, referenceId, route, isRead, and createdAt.
- **`NotificationsRepository`** -- Riverpod provider wrapping Dio calls for fetch, mark-as-read, and mark-all-as-read.
- **`notificationsProvider`** -- `FutureProvider<List<NotificationModel>>` that fetches the notification list.

## How It Works

### Notification List

`NotificationsPage` is a `ConsumerWidget` that watches `notificationsProvider` and renders via `FlatmatesAsyncView`. It shows:

- A header with a "mark all read" action button
- A `ListView.builder` of `FlatmatesNotificationCard` widgets
- Skeleton loading state (`FlatmatesSkeleton.notificationList()`)
- Empty state with icon and localized message

### Type-Based Styling

Each notification type maps to a specific icon, background color, and accent color:

| Type | Icon | Background | Accent |
|------|------|------------|--------|
| `new_match` / `flatmate_new_match` | favorite | pinkSoft | pinkMid |
| `new_message` / `flatmate_new_message` | chat_bubble | blueSoft | blueMid |
| `listing_approved` / `flatmate_listing_approved` | verified | greenSoft | greenMid |
| `visit_scheduled` / `flatmate_visit_scheduled` | notifications | yellowSoft | yellowMid |
| `visit_confirmed` / `flatmate_visit_confirmed` | calendar_month | tealSoft | tealMid |
| default | notifications | coralSoft | accent |

### Unread Indicators

Unread notifications display a terracotta left accent border and a 10px terracotta dot below the timestamp, following the design system's notification card specification.

### Tap Behavior

When a notification is tapped:

1. If unread, marks it as read via `NotificationsRepository.markAsRead()`
2. Navigates based on the notification's `route` field (if present) or resolves a route from the `type` and `referenceId`:
   - `new_match` / `new_message` -> `/chats/{referenceId}`
   - `listing_approved` -> `/flat-details/{referenceId}` or `/post`
   - `visit_scheduled` / `visit_confirmed` -> `/visits`
3. If no route can be resolved, shows a toast: "No action available"

### Time Formatting

Timestamps are formatted relative to now:
- Same day: `jm()` format (e.g., "3:30 PM")
- Yesterday: localized "Yesterday"
- Within 7 days: "N days ago"
- Older: `MMMd()` format (e.g., "Jun 15")

### Mark All Read

The header action button calls `NotificationsRepository.markAllAsRead()` and invalidates `notificationsProvider` to refresh the list.

## Integration Points

- **SSE** -- notification updates can arrive via the SSE event stream. The page invalidates `notificationsProvider` on relevant events.
- **Firebase Messaging** -- push notifications are handled by `NotificationService` in `core/notifications/`, which triggers a refresh of the notification list.
- **Deep Links** -- notification tap routes use the same GoRouter paths as deep links.

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/features/notifications/notifications_page.dart` | Notification list with type-based styling |
| `lib/features/notifications/notifications_repository.dart` | API client for notification CRUD |
| `lib/features/shared/presentation/flatmates_ui.dart` | `FlatmatesNotificationCard` widget |
| `lib/core/notifications/` | Firebase Messaging setup |

# Visits Feature

**Active contributors:** Saksham Mittal, Ravi Sahu

## Purpose

The visits feature allows users to schedule property tours, manage visit requests, and perform actions like confirming, cancelling, or rescheduling visits. It integrates with the chat system to send best-effort notification messages when a visit is requested.

## Directory Layout

```
lib/features/visits/
├── schedule_visit_page.dart           # Visit scheduling form
├── visits_page.dart                   # Visit list with status sections
├── visits_repository.dart             # API client for visit CRUD
├── application/
│   └── visits_actions_controller.dart # Controller for confirm/cancel/reschedule
└── widgets/
    └── visit_card.dart                # Visit card with action chips
```

## Key Abstractions

- **`VisitItem`** -- domain model representing a scheduled visit with id, property title, status, scheduled date, visit context, and optional conversation/counterparty references.
- **`VisitsRepository`** -- Riverpod provider wrapping Dio calls for fetch, schedule, confirm, reschedule, and cancel operations.
- **`VisitsActionsController`** -- application-layer controller that encapsulates confirm/cancel/reschedule mutations, keeping business logic out of widgets.

## How It Works

### Scheduling a Visit

`ScheduleVisitPage` is a `ConsumerStatefulWidget` that accepts a `ConversationSummaryModel` (or a `conversationId` to fetch). The scheduling flow:

1. **Property card** -- displays the property image, title, peer name, and matched date
2. **Calendar picker** -- `CalendarDatePicker` with a 90-day range from today
3. **Time slot selection** -- morning (10 AM), afternoon (3 PM), or evening (6 PM) chips
4. **Note** -- optional text field (180 char limit) for special requirements
5. **Privacy badge** -- trust badge indicating the visit request will be shared with the counterparty

All local UI state (selected date, selected slot, submitting flag) uses file-level `StateProvider` instances that reset on page entry to prevent stale values from previous sessions.

### Visit Submission

On submit, `VisitsRepository.scheduleVisitAndNotify()`:

1. Calls `POST /api/v1/flatmates/visits` with property ID, counterparty user ID, conversation ID, scheduled date (UTC), time slot label, and optional note
2. Sends a best-effort chat message of type `visit_request` to the conversation with visit metadata
3. If the chat message fails, the visit still succeeds (fire-and-forget notification)

After success, `visitsProvider` and `messagesProvider` are invalidated, and the page pops back.

### Visit List

`VisitsPage` organizes visits into three timeline sections:

- **Upcoming** -- visits with status `scheduled` or `confirmed`
- **Requested** -- visits with status `requested` (awaiting confirmation)
- **Past** -- cancelled, completed, or unknown statuses

Each `VisitCard` supports action chips for confirm, cancel, and reschedule. Actions are guarded by `_pendingVisitActionsProvider` (a `StateProvider<Set<int>>`) to prevent double-submission.

### Visit Actions

- **Confirm** -- `PUT /api/v1/flatmates/visits/{id}` with `status: confirmed`
- **Cancel** -- shows a confirmation dialog, then `PUT` with `status: cancelled`
- **Reschedule** -- shows date picker + time picker, validates the new time is in the future, then `PUT` with new `scheduled_date` and `status: requested`

All actions use `VisitsActionsController` and display toast feedback on success or failure.

## Integration Points

- **Chat** -- visit scheduling sends a `visit_request` message type with metadata containing `visit_id`, `status`, `scheduled_date`, and `time_slot_label`.
- **Notifications** -- visit-related notifications (`visit_scheduled`, `visit_confirmed`) route to `/visits`.
- **Bootstrap** -- visit data is fetched independently via `visitsProvider` (not part of the bootstrap payload).

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/features/visits/schedule_visit_page.dart` | Calendar + time slot scheduling form |
| `lib/features/visits/visits_page.dart` | Visit list grouped by status |
| `lib/features/visits/visits_repository.dart` | API client for visit CRUD |
| `lib/features/visits/application/visits_actions_controller.dart` | Confirm/cancel/reschedule controller |
| `lib/features/visits/widgets/visit_card.dart` | Visit card with action chips |
| `lib/core/config/endpoints.dart` | API path constants (`FlatmatesEndpoints.visits`) |

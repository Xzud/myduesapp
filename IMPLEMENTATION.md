# MyDues Implementation Roadmap

## Purpose

This document turns the next recommended product improvements for MyDues into a phased implementation plan that fits the current Flutter + `sqflite` architecture.

## Clarified Goal

Evolve MyDues from a due scheduler into a daily-use payment tracker without destabilizing the current loan split, recurring due, dashboard, and settings flows.

## Current Baseline

The app already supports:

- Dashboard totals, overdue counts, due-today counts, and monthly summaries.
- Loan split creation with billing-day selection and optional interest.
- Recurring bill creation with fixed occurrence generation.
- Overview and all-dues pages with group management and paid/unpaid toggles.
- Billing-day settings, default billing-period mode, and full data reset.

The main current limitations are:

- The `dues` table stores only due-level data.
- Recurring series are pre-generated instead of template-driven.
- Payment state is a `paid` boolean, not a payment ledger.
- Search, filters, notifications, and backup flows do not exist yet.

## Constraints

- Preserve the existing architecture boundaries: `presentation -> application -> domain -> infrastructure`.
- Keep the app local-first and offline-friendly.
- Prefer incremental SQLite migrations over broad rewrites.
- Preserve existing routes and current feature behavior unless a phase explicitly changes it.
- Add tests in the same shape the repo already uses: unit, controller, repository, and widget tests.
- Keep each phase independently shippable.

## Cross-Phase Rules

- Do not introduce large dependencies early unless a phase requires them.
- Do not combine multiple schema-heavy features into one release.
- Favor backward-compatible entity changes where possible.
- When a phase changes persistence, add migration tests before expanding UI behavior.
- For new settings, continue using the existing `settings` key/value table unless the phase requires first-class relational data.

## Recommended Delivery Order

1. Phase 1: Reminders and notification preferences.
2. Phase 2: Search, filters, and quick views.
3. Phase 3: Recurring templates and series-level editing.
4. Phase 4: Partial payments and payment history.
5. Phase 5: Backup, export, and import.

This order gives the app immediate day-to-day value first, then improves navigation, then addresses the larger data-model gaps.

## Phase 1: Reminders And Notification Preferences

### Goal

Notify users before dues become late and make reminder behavior configurable.

### Why This Phase First

The app already computes `overdue`, `due today`, and `upcoming` states. Reminders turn that existing due-date logic into a daily-use feature without changing the core data model.

### Feature Slices

- Global reminder enable/disable setting.
- Reminder lead-time setting such as same day, 1 day before, or 3 days before.
- Scheduled local notification for each future unpaid due.
- Notification cancellation or rescheduling when a due is edited, paid, or deleted.
- App-start reminder sync so pending notifications survive restarts.

### Likely Files To Change

- `pubspec.yaml`
- `lib/main.dart`
- `lib/core/di/injection_container.dart`
- `lib/features/dues/domain/repositories/settings_repository.dart`
- `lib/features/dues/infrastructure/repositories/settings_repository_impl.dart`
- `lib/features/dues/infrastructure/datasources/settings_datasource.dart`
- `lib/features/dues/presentation/pages/settings.dart`
- `lib/features/dues/presentation/controllers/settings_controller.dart`
- `lib/features/dues/presentation/controllers/due_controller.dart`

### Likely New Files

- `lib/core/notifications/notification_service.dart`
- `lib/features/dues/application/usecases/sync_due_reminders.dart`
- `test/sync_due_reminders_test.dart`

### Implementation Steps

1. Add a local notification service abstraction in `core` so plugin details stay out of the feature layers.
2. Extend settings persistence with reminder keys such as `reminders_enabled` and `reminder_offset_days`.
3. Create an application use case that loads future unpaid dues and schedules notifications.
4. Trigger reminder sync after create, update, delete, and paid/unpaid mutations.
5. Add reminder controls to Settings.
6. Sync pending notifications during app startup.

### Acceptance Checklist

- Users can enable or disable reminders from Settings.
- Users can choose a reminder lead time.
- Creating a future due schedules a notification.
- Marking a due paid cancels its pending notification.
- Editing a due date reschedules the notification.
- Deleting a due removes its notification.

### Review And Testing Checklist

- Add repository tests for reminder settings persistence.
- Add use-case tests with a fake notification service.
- Add controller tests to confirm reminder sync is triggered after due mutations.
- Manually verify notifications on a real device or emulator because widget tests will not prove OS delivery.
- Run `flutter test`.
- Run `flutter analyze`.

### Risks And Decisions

- Package choice is a dependency decision. Recommended: a local notifications package plus timezone-safe scheduling.
- The first release should use one global reminder policy, not per-due custom reminder rules.
- Android and iOS permission flows should be handled in this phase, not deferred.

## Phase 2: Search, Filters, And Quick Views

### Goal

Make large due lists easy to navigate without changing stored due data.

### Why This Phase Second

It improves usability immediately and can mostly operate on the data already returned by the current use cases.

### Feature Slices

- Search dues by partial name.
- Filter by status: all, paid, unpaid, overdue, due today, upcoming.
- Filter by type: recurring, loan/installment, single due.
- Filter by month.
- Built-in quick views for common states.
- Persist the last-used filter state.

### Likely Files To Change

- `lib/features/dues/presentation/pages/dues.dart`
- `lib/features/dues/presentation/pages/all_dues_showcase.dart`
- `lib/features/dues/presentation/controllers/due_controller.dart`
- `lib/features/dues/domain/repositories/settings_repository.dart`
- `lib/features/dues/infrastructure/repositories/settings_repository_impl.dart`
- `lib/features/dues/infrastructure/datasources/settings_datasource.dart`

### Likely New Files

- `lib/features/dues/application/usecases/due_filters.dart`
- `lib/features/dues/application/usecases/filter_dues.dart`
- `test/filter_dues_test.dart`

### Implementation Steps

1. Add a shared filtering model so overview pages use one status and type vocabulary.
2. Implement a filtering use case or helper that can work on fetched dues without mutating persistence.
3. Extend `DueController` or page state to manage search text, selected filters, and current quick view.
4. Add search input and filter chips to Overview and All Dues.
5. Persist the last-used filter selection in Settings.
6. Add empty states that clearly describe the active filter instead of looking like data loss.

### Acceptance Checklist

- Users can search dues by name from both list-heavy pages.
- Users can filter to overdue, unpaid, due today, and recurring items.
- Filters do not change due records in storage.
- Clearing filters restores the original grouped list.
- Empty states explain that filters returned no results.

### Review And Testing Checklist

- Add unit tests for filtering combinations.
- Add widget tests for search, chip toggles, and empty-state behavior.
- Verify grouping still works after filtering.
- Run `flutter test`.
- Run `flutter analyze`.

### Risks And Decisions

- Keep the first release simple: built-in quick views plus persisted last selection.
- Do not build user-defined saved-view presets yet unless the base filtering model proves stable.
- Shared filter logic should be centralized early to avoid divergence between Overview and All Dues.

## Phase 3: Recurring Templates And Series-Level Editing

### Goal

Replace fixed recurring occurrence generation with a true recurring-series model that supports future edits and graceful stop behavior.

### Why This Phase Third

The current recurring implementation works, but it stores a pre-generated batch of dues and uses `loanId` as the recurring group key. That is functional, but it will not scale cleanly to series editing or long-lived recurring schedules.

### Feature Slices

- First-class recurring template storage.
- Rolling generation of future due instances from a template.
- End recurring series without deleting paid history.
- Edit recurring series from a chosen boundary such as "this occurrence only" or "future occurrences".
- Safer recurring group identity that does not overload `loanId`.

### Likely Files To Change

- `lib/core/database/database_helper.dart`
- `lib/features/dues/domain/entities/due_entity.dart`
- `lib/features/dues/infrastructure/models/due_model.dart`
- `lib/features/dues/domain/repositories/due_repository.dart`
- `lib/features/dues/infrastructure/repositories/due_repository_impl.dart`
- `lib/features/dues/infrastructure/datasources/due_datasource.dart`
- `lib/features/dues/application/usecases/create_recurring_due.dart`
- `lib/features/dues/presentation/pages/create.dart`
- `lib/features/dues/presentation/pages/all_dues_showcase.dart`
- `lib/features/dues/presentation/pages/due_detail.dart`
- `lib/features/dues/presentation/controllers/due_form_controller.dart`
- `lib/features/dues/presentation/controllers/due_controller.dart`

### Likely New Files

- `lib/features/dues/domain/entities/recurring_template_entity.dart`
- `lib/features/dues/infrastructure/models/recurring_template_model.dart`
- `lib/features/dues/application/usecases/generate_recurring_occurrences.dart`
- `lib/features/dues/application/usecases/update_recurring_series.dart`
- `test/generate_recurring_occurrences_test.dart`

### Implementation Steps

1. Add a new recurring template table instead of storing recurring behavior only on due rows.
2. Add a stable template ID reference from each generated recurring due.
3. Decide on a rolling generation window. Recommended: keep the next 3 to 6 unpaid occurrences materialized.
4. Update recurring creation so it creates a template first, then generates initial due instances.
5. Replace "end recurring payment" deletion behavior with template deactivation plus cleanup of future unpaid generated rows.
6. Add series-edit flows in UI, starting with "future occurrences" before supporting "this occurrence only".
7. Update grouping logic in list pages to use explicit recurring identity.

### Acceptance Checklist

- Recurring bills are backed by a template, not only a pre-generated batch.
- Ending a recurring series preserves paid history.
- Users can change future recurring amount, billing day, or interval from the UI.
- The app does not create duplicate recurring dues when generation runs more than once.
- Existing recurring data migrates cleanly.

### Review And Testing Checklist

- Add migration tests from the current recurring-row format.
- Add generator tests for month-end clamping and interval spacing.
- Add tests to confirm duplicate generation is prevented.
- Add widget tests for ending a series and editing future occurrences.
- Run `flutter test`.
- Run `flutter analyze`.

### Risks And Decisions

- This is the first major schema change and should not be bundled with Phase 4.
- Existing recurring groups currently reuse `loanId`; this phase should introduce a more explicit identity model.
- "This occurrence only" edits are more complex because they can split a series. The recommended first release supports "future occurrences" first.

## Phase 4: Partial Payments And Payment History

### Goal

Track real payment activity instead of only full paid/unpaid state.

### Why This Phase Fourth

This is the highest-value data-model upgrade, but it changes status calculations, dashboard amounts, list behavior, and due detail UX. It should land only after the lower-risk usability features are stable.

### Feature Slices

- Payment ledger for each due.
- Remaining balance and total paid calculations.
- Partial payment status in UI.
- Payment history list in due details.
- Ability to add and remove payment entries.
- Dashboard summaries based on remaining balance, not only boolean paid status.

### Likely Files To Change

- `lib/core/database/database_helper.dart`
- `lib/features/dues/domain/entities/due_entity.dart`
- `lib/features/dues/domain/entities/dashboard_summary_entity.dart`
- `lib/features/dues/infrastructure/models/due_model.dart`
- `lib/features/dues/domain/repositories/due_repository.dart`
- `lib/features/dues/infrastructure/repositories/due_repository_impl.dart`
- `lib/features/dues/infrastructure/datasources/due_datasource.dart`
- `lib/features/dues/application/usecases/get_all_dues.dart`
- `lib/features/dues/application/usecases/get_dashboard_summary.dart`
- `lib/features/dues/presentation/pages/due_detail.dart`
- `lib/features/dues/presentation/pages/dues.dart`
- `lib/features/dues/presentation/pages/all_dues_showcase.dart`
- `lib/features/dues/presentation/controllers/due_controller.dart`

### Likely New Files

- `lib/features/dues/domain/entities/payment_entity.dart`
- `lib/features/dues/infrastructure/models/payment_model.dart`
- `lib/features/dues/application/usecases/add_due_payment.dart`
- `lib/features/dues/application/usecases/delete_due_payment.dart`
- `test/add_due_payment_test.dart`

### Implementation Steps

1. Add a `payments` table keyed to dues.
2. Define payment-domain entities and repository methods for add, list, and delete operations.
3. Update due summaries to derive `paid`, `remaining`, and `partial` state from payment rows.
4. Add payment-entry UI in due details.
5. Update dashboards and list pages to use remaining balance for overdue and unpaid totals.
6. Decide how to migrate current fully paid dues. Recommended: backfill a synthetic full-payment record for legacy paid rows.

### Acceptance Checklist

- Users can record a payment smaller than the due amount.
- Remaining balance updates immediately after a payment is saved.
- A due becomes fully paid only when total payments meet or exceed its amount.
- Payment history is visible in due details.
- Removing a payment recalculates due status correctly.
- Dashboard unpaid and overdue amounts reflect remaining balance instead of original amount.

### Review And Testing Checklist

- Add repository tests for payment CRUD.
- Add summary tests for unpaid, partial, and fully paid combinations.
- Add widget tests for adding and deleting payment rows.
- Add migration tests for legacy paid dues.
- Run `flutter test`.
- Run `flutter analyze`.

### Risks And Decisions

- This phase changes business rules, not only storage.
- The migration approach for existing `paid` rows is a product decision. Recommended: generate a synthetic legacy payment so old data stays internally consistent.
- Keep payment entry simple at first: amount and payment date are required; notes are optional and can be added later.

## Phase 5: Backup, Export, And Import

### Goal

Protect user data and make local-only usage safer.

### Why This Phase Fifth

Backup becomes much more valuable once recurring templates and payment history exist. Deferring it until later avoids repeated export-format churn while the schema is still changing.

### Feature Slices

- Full JSON backup export.
- Full JSON import with validation.
- Data version metadata in export files.
- Optional CSV export for reporting after JSON backup is stable.

### Likely Files To Change

- `pubspec.yaml`
- `lib/features/dues/presentation/pages/settings.dart`
- `lib/features/dues/presentation/controllers/settings_controller.dart`
- `lib/features/dues/domain/repositories/due_repository.dart`
- `lib/features/dues/domain/repositories/settings_repository.dart`

### Likely New Files

- `lib/features/dues/application/usecases/export_app_data.dart`
- `lib/features/dues/application/usecases/import_app_data.dart`
- `lib/features/dues/application/usecases/serialize_app_data.dart`
- `test/export_import_app_data_test.dart`

### Implementation Steps

1. Define a versioned JSON backup format that covers dues, settings, recurring templates, and payments.
2. Add export use cases that assemble current app data into that payload.
3. Add import validation before any write occurs.
4. Perform imports inside a transaction so malformed files cannot partially overwrite local data.
5. Add Settings actions for export and import.
6. After JSON round-trip is stable, consider CSV export for user-readable reporting.

### Acceptance Checklist

- Users can export a full backup file.
- Users can restore from a valid backup after resetting data.
- Invalid backup files are rejected without partial writes.
- Imported data restores dashboard totals and list views correctly.
- Backup format includes a schema version field.

### Review And Testing Checklist

- Add round-trip tests for export then import.
- Add invalid-file tests.
- Add transaction safety tests if the datasource layer changes.
- Manually verify file selection and share behavior on target platforms.
- Run `flutter test`.
- Run `flutter analyze`.

### Risks And Decisions

- File access and sharing differ by platform and may require platform-specific testing.
- JSON should be the primary backup format; CSV alone is not enough for restore.
- Import conflict behavior should be explicit. Recommended first release: replace local data after confirmation instead of merge.

## Suggested Milestones

### Milestone A

Ship Phases 1 and 2 together only if reminder work stays small. Otherwise ship Phase 1 on its own.

### Milestone B

Ship Phase 3 as its own release because it changes the recurring data model.

### Milestone C

Ship Phase 4 alone. It changes core payment semantics and deserves focused validation.

### Milestone D

Ship Phase 5 after Phase 4 stabilizes so backup includes the newer schema.

## Global Success Criteria

- The app remains stable for existing loan split and one-time due flows throughout the roadmap.
- Every schema-changing phase includes migration coverage.
- Every user-visible phase includes widget or controller coverage for the new flow.
- Dashboard numbers stay internally consistent after each phase.
- No phase requires a backend or breaks offline-only usage.

## Default Assumptions

- Currency remains PHP.
- The app remains single-user and local-only.
- Authentication, cloud sync, and multi-device merge are out of scope for this roadmap.
- Categories, tags, notes, and attachments are not part of the current phased plan.

## Final Recommendation

If implementation starts immediately, begin with Phase 1 and keep the first release narrow:

- global reminder toggle
- one reminder lead-time setting
- unpaid future due scheduling
- automatic resync after due mutations

That gives MyDues a meaningful daily-use upgrade without forcing a schema rewrite first.

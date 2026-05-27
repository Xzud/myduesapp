 ## MyDues Loan Split + Billing Period Plan

  ### Summary

  Add first-class “loan with installments” support so you can enter a
  principal amount (e.g., 5000 PHP), split it across a selected number of
  periods, and automatically assign installment due dates based on
  configurable billing days in Settings. Payment status is tracked per
  installment, and the loan is complete when all installments are paid.

  ### Implementation Changes

  - Data model and storage
      - Add a settings table in SQLite (migration from DB version 1 to version
        2) for persisted app settings.
      - Persist billing period days under a single key (e.g., billing_dates)
        as JSON.
      - Extend due storage to represent installment-level records with a
        shared loan_id (or equivalent group key), installment_index,
        installment_count, due_date, and amount.
      - Keep existing fields needed for current UI compatibility where
        practical (name, paid, timestamps).
  - Domain/use cases
      - Implement GetPaymentDates to actually read persisted billing dates
        from SettingsRepository.
      - Add/extend a use case for “Create Loan Split”:
          - inputs: title, principal amount, number of splits, optional start
            date.
          - behavior: compute installment amounts using even split + remainder
            on last installment.
          - behavior: assign due dates by cycling through upcoming configured
            day-of-month values.
          - output: create all installment dues in one operation.
      - Update due retrieval/grouping to include due-date ordering and
        installment metadata for UI rendering.
  - Controllers + UI
      - Settings page: make add/remove billing days persist to DB, validate 1–
        31, prevent duplicates, sort ascending.
      - Home/create page: replace single-due flow with loan split form fields:
          - title, principal amount (PHP), number of installments, optional
            start date.
          - preview of computed installment amounts + due dates before submit.
      - Overview page: render installments with clear grouping by loan and
        month; checking one item marks only that installment paid; show loan
        complete when all installments are paid.
  - Wiring
      - Update datasource/repository interfaces and DI registrations to
        include new settings persistence and loan-split creation flow without
        breaking existing architecture (datasource -> repository -> usecase ->
        controller).

  ### Test Plan

  - Unit tests for split calculation:
      - 5000 / 3 yields two equal rounded installments plus remainder on last;
        total equals 5000.00.
      - edge cases: small amounts, large split counts, invalid split count
        (<1).
  - Unit tests for due-date generation from billing days:
      - single billing day; multiple billing days; month rollover behavior.
  - Repository/datasource tests:
      - settings read/write round-trip for billing dates.
      - bulk installment insert creates expected count and fields.
  - Controller tests:
      - create flow loading/error states.
      - settings add/remove persistence and validation behavior.
  - Widget tests (focused):
      - split form validation.
      - preview rendering.
      - overview checkbox updates installment-only status.

  ### Assumptions and Defaults

  - Billing period basis is day(s) of month list from Settings.
  - Split rule is even installments with centavo remainder applied to last
    installment.
  - Paid behavior is per installment only; loan completes automatically when
    all installments are paid.
  - Currency display is PHP (Php/₱) with 2 decimal places.

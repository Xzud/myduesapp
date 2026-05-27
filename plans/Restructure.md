# Flutter Clean Architecture Restructure and Agent Workflow Plan

## Decision

Keep one Flutter application repository. Do not split the repo into permanent
`frontend/` and `backend/` root folders.

The project should be separated by architecture layer inside each feature:

```text
lib/
  core/
    di/
    errors/
    network/
  features/
    auth/
      presentation/
      application/
      domain/
      infrastructure/
    dues/
      presentation/
      application/
      domain/
      infrastructure/
    payments/
      presentation/
      application/
      domain/
      infrastructure/
    profile/
      presentation/
      application/
      domain/
      infrastructure/
```

This is feature-first Clean Architecture. It gives each AI agent a clear
workspace and keeps source ownership aligned with runtime dependencies.

## Current Repository Issues

The current dues feature mostly follows a layered shape, but it still uses
legacy naming and ownership boundaries:

```text
lib/features/dues/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    usecases/
  presentation/
    controllers/
    pages/
    widgets/
```

Problems to resolve:

- `data/` should become `infrastructure/` because it owns persistence, models,
  external systems, repository implementations, SQLite/Firebase/HTTP clients,
  and serialization.
- Use cases currently live under `domain/usecases/`. They should move to
  `application/` so domain remains pure business language and contracts.
- Repository contracts should live in `domain/`, not under `data/`.
- UI controllers may remain under `presentation/` if they contain presentation
  state only. If a controller starts coordinating workflows, move that logic
  into `application/`.
- Generated/build artifacts exist in the working tree and should remain
  ignored so agents do not read, edit, or commit them.

## Target Layer Responsibilities

### `presentation/`

Owns Flutter UI and presentation state.

Allowed:

- Pages, widgets, themes, navigation, layout, animations.
- View models/controllers that expose UI state and call application use cases.
- Formatting that is strictly visual.

Must not know:

- SQLite, Firebase, REST, Dio, Supabase, HTTP, file storage, or cache details.
- Repository implementations.
- DTOs, database models, API responses, table names, endpoint paths.

Presentation depends on:

- `application/` use cases.
- `domain/` entities/value objects when needed for display.

### `application/`

Owns app workflows and use cases.

Allowed:

- Use cases such as `GetDuesUseCase`, `CreateDueUseCase`,
  `CreateSplitDueUseCase`, `SetDuePaidUseCase`.
- Request/command objects for use cases.
- Application-level validation and orchestration.
- Transaction boundaries expressed through repository contracts.

Must not know:

- Flutter widgets/pages/themes.
- SQLite/Firebase/REST/Dio/Supabase/HTTP implementation details.
- DTO serialization formats.

Application depends on:

- `domain/` entities, value objects, failures, repository contracts.

### `domain/`

Owns business language and contracts.

Allowed:

- Entities such as `Due`, `PaymentDate`, `BillingPeriod`, `User`.
- Value objects such as `Money`, `DueDate`, `BillingDay`.
- Repository contracts such as `DuesRepository`.
- Pure domain services when behavior does not belong on a single entity.
- Domain failures and validation rules.

Must not know:

- Flutter.
- SQLite, Firebase, REST, Dio, Supabase, HTTP.
- JSON/database model classes.
- Dependency injection containers.

Domain depends on:

- Dart core only, except for deliberately approved pure packages.

### `infrastructure/`

Owns external systems and persistence.

Allowed:

- SQLite datasources, Firebase clients, REST clients, local cache, file storage.
- DTOs and database models.
- Repository implementations.
- Mappers between infrastructure models and domain entities.
- Migrations and schema-specific code.

Must not know:

- Flutter widgets/pages.
- Presentation controllers.

Infrastructure depends on:

- `domain/` contracts/entities.
- External packages required to implement those contracts.

### `core/`

Owns cross-feature primitives only.

Allowed:

- Dependency injection setup under `core/di/`.
- Shared error/failure types under `core/errors/`.
- Shared network configuration under `core/network/`.
- Shared database setup under `core/database/` until migrated or if the DB is
  intentionally app-wide.

Must not become:

- A dumping ground for `utils/`, `helpers/`, feature-specific services, or
  unrelated shared logic.

## Target Dues Structure

The existing dues feature should be migrated toward:

```text
lib/features/dues/
  presentation/
    controllers/
    pages/
    widgets/
  application/
    usecases/
    commands/
  domain/
    entities/
    value_objects/
    repositories/
    failures/
  infrastructure/
    datasources/
    models/
    repositories/
    mappers/
```

Suggested current-file mapping:

```text
lib/features/dues/data/datasources/*
  -> lib/features/dues/infrastructure/datasources/*

lib/features/dues/data/models/*
  -> lib/features/dues/infrastructure/models/*

lib/features/dues/data/repositories/implementations/*
  -> lib/features/dues/infrastructure/repositories/*

lib/features/dues/data/repositories/* repository contracts
  -> lib/features/dues/domain/repositories/*

lib/features/dues/domain/usecases/*
  -> lib/features/dues/application/usecases/*

lib/features/dues/domain/entities/*
  -> lib/features/dues/domain/entities/*

lib/features/dues/presentation/*
  -> lib/features/dues/presentation/*
```

## Dependency Rule

Dependencies must point inward:

```text
presentation -> application -> domain
infrastructure -> domain
application -> domain
```

Infrastructure is wired to application through dependency injection, not direct
UI imports.

Forbidden dependency examples:

- `presentation -> infrastructure`
- `presentation -> sqflite`
- `presentation -> firebase_*`
- `presentation -> dio`
- `domain -> infrastructure`
- `domain -> Flutter`
- `application -> Flutter widgets`
- `application -> HTTP/SQLite/Firebase clients`

## Contracts First Workflow

All feature work starts by defining or updating contracts before implementation.

Example:

```dart
abstract class DuesRepository {
  Future<List<Due>> getDues();
}
```

Workflow:

1. Domain contract is defined first.
2. App-logic agent creates or updates use cases against that contract.
3. Backend-infra agent implements the contract.
4. Frontend-ui agent consumes application use cases only.

This prevents UI and infrastructure from inventing incompatible models or
duplicating business rules.

## Branch Strategy

Use short-lived feature branches. Do not keep permanent frontend/backend
branches.

Recommended branches:

```text
feature/ui-work
feature/app-logic
feature/backend-infra
```

Branch rules:

| Branch | Owns | Must Not Touch |
| --- | --- | --- |
| `feature/ui-work` | Widgets, screens, themes, navigation, presentation state | API clients, DB logic, repository implementations, infrastructure models |
| `feature/app-logic` | Use cases, domain models, repository contracts, validation rules | Flutter UI, HTTP clients, Firebase, SQLite implementations |
| `feature/backend-infra` | API integration, repositories, persistence, Firebase, caching, mappers | Widgets, pages, themes, navigation |

Branches should be merged back to `main` frequently after tests pass. `main`
must stay stable.

## AI Agent Workspace Rules

### Frontend UI Agent

Allowed write paths:

```text
lib/features/*/presentation/
test/**/*widget*
test/**/*controller*
```

Read-only paths:

```text
lib/features/*/application/
lib/features/*/domain/
lib/core/
```

Forbidden write paths:

```text
lib/features/*/infrastructure/
lib/core/database/
android/
ios/
linux/
macos/
web/
windows/
```

Hard rule: UI must call use cases. UI must not instantiate repositories,
datasources, database helpers, HTTP clients, or Firebase services.

### App Logic Agent

Allowed write paths:

```text
lib/features/*/application/
lib/features/*/domain/
test/**/*usecase*
test/**/*domain*
```

Read-only paths:

```text
lib/features/*/presentation/
lib/features/*/infrastructure/
lib/core/
```

Forbidden write paths:

```text
lib/features/*/presentation/
lib/features/*/infrastructure/
android/
ios/
linux/
macos/
web/
windows/
```

Hard rule: application/domain code must not import Flutter widgets, SQLite,
Firebase, Dio, Supabase, or HTTP clients.

### Backend Infra Agent

Allowed write paths:

```text
lib/features/*/infrastructure/
lib/core/database/
lib/core/di/
test/**/*repository*
test/**/*datasource*
test/**/*infrastructure*
```

Read-only paths:

```text
lib/features/*/domain/
lib/features/*/application/
```

Forbidden write paths:

```text
lib/features/*/presentation/
```

Hard rule: infrastructure implements domain contracts. It must not change UI to
make infrastructure easier.

## Generated and Local Artifacts

These should not be committed or edited by agents:

```text
.dart_tool/
build/
.idea/
.gradle/
**/.gradle/
.flutter-plugins
.flutter-plugins-dependencies
.packages
```

`pubspec.lock` policy:

- For an application repo, keeping `pubspec.lock` committed is usually
  acceptable and improves reproducible builds.
- If the team decides to ignore it, add it to `.gitignore` and remove it from
  git tracking intentionally in a separate commit.
- Current repository state has `pubspec.lock` tracked, so the safer default is
  to keep it tracked until policy changes.

If generated artifacts are already tracked, ignoring them is not enough. Remove
them from git tracking with `git rm --cached` in a dedicated cleanup commit.

Suggested cleanup command after review:

```bash
git rm --cached -r .dart_tool build .idea .gradle android/.gradle ios/Flutter/ephemeral macos/Flutter/ephemeral
```

Only run this after confirming the files are actually tracked and should be
removed from version control.

## Migration Plan

### Phase 0: Repository Hygiene

Goal: stop agents from touching generated artifacts.

Tasks:

- Ensure `.gitignore` covers `.dart_tool/`, `build/`, `.idea/`, `.gradle/`,
  `**/.gradle/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, and
  `.packages`.
- Check tracked generated files with:

```bash
git ls-files .idea .dart_tool build .gradle android/.gradle ios/Flutter/ephemeral macos/Flutter/ephemeral
```

- Remove tracked generated files with `git rm --cached` only after review.

Validation:

```bash
git status --short
flutter analyze
flutter test
```

### Phase 1: Define Contracts

Goal: make domain contracts the stable boundary between agents.

Tasks:

- Move repository interfaces into `lib/features/dues/domain/repositories/`.
- Ensure entities are infrastructure-free and Flutter-free.
- Add missing value objects for concepts that need rules, such as billing day,
  money, and due date.
- Keep use cases compiling against domain contracts.

Validation:

```bash
flutter test test/get_all_dues_test.dart
flutter analyze
```

### Phase 2: Move Use Cases to Application

Goal: make workflows explicit.

Tasks:

- Create `lib/features/dues/application/usecases/`.
- Move use cases from `domain/usecases/` into `application/usecases/`.
- Update imports in controllers, tests, and dependency injection.
- Keep domain pure.

Validation:

```bash
flutter test test/create_due_test.dart test/get_all_dues_test.dart test/reset_all_data_test.dart
flutter analyze
```

### Phase 3: Rename Data to Infrastructure

Goal: make persistence ownership explicit.

Tasks:

- Create `lib/features/dues/infrastructure/`.
- Move datasources, models, mappers, and repository implementations from
  `data/` to `infrastructure/`.
- Keep only contracts in `domain/repositories/`.
- Update `lib/injection_container.dart` or migrate DI to `lib/core/di/`.

Validation:

```bash
flutter test
flutter analyze
```

### Phase 4: Add Missing Feature Shells

Goal: make future features follow the same architecture from day one.

Tasks:

- Create feature folders only when a feature is ready to be implemented.
- For each new feature, create the same four-layer structure:
  `presentation/`, `application/`, `domain/`, `infrastructure/`.
- Avoid empty placeholder features unless they are part of an active branch.

Validation:

```bash
find lib/features -maxdepth 3 -type d | sort
flutter analyze
```

### Phase 5: Enforce Agent Boundaries

Goal: make multi-agent work safe.

Tasks:

- Use the prompts in `plans/skill-plan/` to create future agent skills.
- Assign each branch to one agent role.
- Require agents to print changed files before finalizing.
- Reject changes that cross forbidden paths unless explicitly approved.

Validation:

```bash
git diff --name-only
flutter test
flutter analyze
```

## Pull Request Checklist

Every PR should include:

- Branch role: `frontend-ui`, `app-logic`, or `backend-infra`.
- Files changed grouped by layer.
- Confirmation that forbidden paths were not touched.
- Test evidence from `flutter test`.
- Static analysis evidence from `flutter analyze`.
- Screenshots/GIFs for UI changes.

## Review Checklist

Reject or request changes when:

- UI imports infrastructure.
- Domain imports Flutter or infrastructure packages.
- Application imports SQLite/Firebase/HTTP/Dio/Supabase.
- Repository contracts are duplicated across layers.
- DTOs leak into UI or domain.
- Generated artifacts are committed.
- A branch changes unrelated layers without explicit approval.

## Completion Criteria

The restructure is complete when:

- Each feature uses `presentation/application/domain/infrastructure`.
- Repository contracts live in `domain`.
- Use cases live in `application`.
- Implementations, datasources, DTOs, and mappers live in `infrastructure`.
- UI calls use cases only.
- Generated artifacts are ignored and untracked.
- `flutter test` and `flutter analyze` pass on `main`.

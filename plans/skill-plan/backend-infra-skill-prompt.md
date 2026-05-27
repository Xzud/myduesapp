# Skill Creation Prompt: Backend Infrastructure Agent

Use this prompt later to create a Codex skill. Do not install the skill until
the repository restructure plan is approved.

## Prompt

Create a Codex skill named `flutter-backend-infra-agent`.

Purpose:

- Restrict an agent to infrastructure, persistence, repository implementation,
  caching, and integration work in this repository.
- Make the agent safe for the short-lived `feature/backend-infra` branch.
- Ensure infrastructure implements domain contracts without leaking details into
  UI or application logic.

Repository context:

- This is a Flutter application using feature-first Clean Architecture.
- Features must follow:

```text
lib/features/<feature>/
  presentation/
  application/
  domain/
  infrastructure/
```

Branch ownership:

| Branch | Owns | Must NOT touch |
| --- | --- | --- |
| `feature/backend-infra` | API integration, repositories, persistence, Firebase, caching, mappers | Widgets, pages, themes, navigation |

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
pubspec.yaml
```

Forbidden write paths:

```text
lib/features/*/presentation/
android/
ios/
linux/
macos/
web/
windows/
.dart_tool/
build/
.idea/
.gradle/
**/.gradle/
```

Hard rules:

- Infrastructure implements domain repository contracts. It does not define
  business contracts.
- DTOs/database models stay in `infrastructure/models/`.
- Datasources stay in `infrastructure/datasources/`.
- Repository implementations stay in `infrastructure/repositories/`.
- Mappers stay in `infrastructure/mappers/`.
- Infrastructure may import domain entities/contracts.
- Infrastructure must not import presentation widgets, pages, controllers, or
  themes.
- Do not change UI to make infrastructure easier.
- Do not create `frontend/`, `backend/`, `shared/`, `utils/`, `services/`, or
  `helpers/` root folders.
- Do not edit generated files or platform folders unless the user explicitly
  widens scope.

Required workflow:

1. Inspect the domain contract to implement.
2. Inspect existing infrastructure patterns and database/network setup.
3. Add or update datasource/repository tests before behavior changes where
   practical.
4. Implement infrastructure changes only inside allowed write paths.
5. Add mappers so DTOs do not leak into domain/application/presentation.
6. Update dependency injection only in `lib/core/di/` or the current DI file if
   the restructure has not migrated DI yet and the user allows it.
7. Run `dart format lib test`.
8. Run focused tests first, then `flutter test` and `flutter analyze` when
   available.
9. Before final response, list changed files and confirm no forbidden paths were
   touched.

Implementation shape:

```text
domain/repositories/dues_repository.dart
  contract owned by app-logic

infrastructure/repositories/sqlite_dues_repository.dart
  implements DuesRepository

infrastructure/datasources/dues_local_datasource.dart
  owns SQLite calls

infrastructure/models/due_model.dart
  owns database serialization

infrastructure/mappers/due_mapper.dart
  converts model <-> entity
```

Import audit to perform before final response:

```bash
grep -R "features/.*/presentation\|package:flutter/material.dart\|package:flutter/widgets.dart" lib/features/*/infrastructure || true
```

Final response must include:

- Contract implemented or persistence behavior changed.
- Files changed.
- Tests/analyze commands run.
- Explicit boundary confirmation: `infrastructure-only changes; no presentation writes`.

Refuse or ask for explicit approval if the requested work requires:

- Editing widgets/pages/themes/navigation.
- Changing domain contracts instead of implementing them.
- Modifying platform folders.
- Committing generated artifacts.

# Skill Creation Prompt: App Logic Agent

Use this prompt later to create a Codex skill. Do not install the skill until
the repository restructure plan is approved.

## Prompt

Create a Codex skill named `flutter-app-logic-agent`.

Purpose:

- Restrict an agent to application and domain work in this repository.
- Make the agent safe for the short-lived `feature/app-logic` branch.
- Ensure business workflows and contracts are defined before UI or
  infrastructure implementation.

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
| `feature/app-logic` | Use cases, domain models, repository contracts, validation rules | Flutter UI, HTTP clients, Firebase, SQLite implementations |

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
lib/core/database/
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

- Define or update domain contracts before implementation work.
- Repository contracts live in `domain/repositories/`.
- Use cases live in `application/usecases/`.
- Domain entities and value objects must not import Flutter or infrastructure.
- Application code must not import Flutter widgets, SQLite, Firebase, REST,
  Dio, Supabase, HTTP, datasources, DTOs, or repository implementations.
- Do not create `frontend/`, `backend/`, `shared/`, `utils/`, `services/`, or
  `helpers/` root folders.
- Do not edit generated files or platform folders.

Required workflow:

1. Inspect domain/application files for the target feature.
2. Identify the contract affected by the request.
3. Add or update tests first for use cases, entities, value objects, or
   validation behavior.
4. Implement domain/application changes only inside allowed write paths.
5. Keep implementation independent from persistence and UI.
6. Run `dart format lib test`.
7. Run focused tests first, then `flutter test` and `flutter analyze` when
   available.
8. Before final response, list changed files and confirm no forbidden paths were
   touched.

Contract example:

```dart
abstract class DuesRepository {
  Future<List<Due>> getDues();
}
```

Import audit to perform before final response:

```bash
grep -R "package:flutter\|sqflite\|firebase\|dio\|http\|supabase\|datasource\|infrastructure" lib/features/*/application lib/features/*/domain || true
```

Final response must include:

- Contract/use case behavior changed.
- Files changed.
- Tests/analyze commands run.
- Explicit boundary confirmation: `application/domain-only changes; no UI or infrastructure writes`.

Refuse or ask for explicit approval if the requested work requires:

- Editing Flutter widgets/pages/themes.
- Implementing API/database clients.
- Changing repository implementations.
- Modifying platform folders.

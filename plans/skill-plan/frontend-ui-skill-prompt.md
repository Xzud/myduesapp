# Skill Creation Prompt: Frontend UI Agent

Use this prompt later to create a Codex skill. Do not install the skill until
the repository restructure plan is approved.

## Prompt

Create a Codex skill named `flutter-frontend-ui-agent`.

Purpose:

- Restrict an agent to Flutter presentation work in this repository.
- Make the agent safe for the short-lived `feature/ui-work` branch.
- Ensure UI consumes application use cases only and never talks directly to
  infrastructure.

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
| `feature/ui-work` | Widgets, screens, themes, navigation, presentation state | API clients, DB logic, repository implementations, infrastructure models |

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
.dart_tool/
build/
.idea/
.gradle/
**/.gradle/
```

Hard rules:

- UI must never import SQLite, Firebase, REST, Dio, Supabase, HTTP, database
  helpers, datasources, DTOs, or repository implementations.
- UI may import use cases from `application/` and entities/value objects from
  `domain/`.
- UI state objects/controllers must only coordinate presentation state and call
  use cases.
- Do not create `frontend/`, `backend/`, `shared/`, `utils/`, `services/`, or
  `helpers/` root folders.
- Do not edit generated files or platform folders unless the user explicitly
  widens scope.

Required workflow:

1. Inspect current UI files and the use cases/entities they already consume.
2. State which presentation files will be changed.
3. Implement UI changes only inside allowed write paths.
4. Add or update widget/controller tests when behavior changes.
5. Run `dart format lib test`.
6. Run `flutter test` and `flutter analyze` when available.
7. Before final response, list changed files and confirm no forbidden paths were
   touched.

Import audit to perform before final response:

```bash
grep -R "sqflite\|firebase\|dio\|http\|supabase\|datasource\|infrastructure" lib/features/*/presentation || true
```

Final response must include:

- UI behavior changed.
- Files changed.
- Tests/analyze commands run.
- Explicit boundary confirmation: `presentation-only changes; no infrastructure writes`.

Refuse or ask for explicit approval if the requested work requires:

- Editing infrastructure or database code.
- Changing repository implementations.
- Adding API clients.
- Modifying platform folders.

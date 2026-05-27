# Repository Guidelines

## Project Structure & Module Organization
This repository is a Flutter app with a feature-first structure centered on dues management.

- `lib/main.dart`: app entry and route wiring.
- `lib/injection_container.dart`: dependency injection (`get_it`) registrations.
- `lib/core/database/`: SQLite setup (`sqflite`) and migrations.
- `lib/features/dues/`: feature layers (`data`, `domain`, `presentation`) for models, repositories, use cases, controllers, and pages.
- `test/`: unit and widget tests (e.g., `create_due_test.dart`, `get_all_dues_test.dart`, `widget_test.dart`).
- Platform folders: `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`.

## Build, Test, and Development Commands
- `flutter pub get`: install/update dependencies from `pubspec.yaml`.
- `flutter run`: run locally on a connected emulator/device.
- `flutter test`: run all unit/widget tests.
- `flutter analyze`: run static analysis using `analysis_options.yaml`.
- `dart format lib test`: format source and tests.

Run commands from the repository root.

## Coding Style & Naming Conventions
Follow standard Dart/Flutter style:

- 2-space indentation, no tabs.
- Types/classes: `PascalCase` (`DueFormController`).
- Methods/variables/files: `lowerCamelCase` for symbols, `snake_case.dart` for filenames.
- Keep layer boundaries clean: presentation -> domain -> data/infrastructure.
- Prefer small, focused use cases and repository interfaces over cross-layer logic leakage.

## Testing Guidelines
Tests use `flutter_test` and `mocktail`.

- Add tests before or with behavior changes (TDD-first for new features/fixes).
- Name tests by behavior, e.g., `should return empty list when no dues exist`.
- Cover success, validation/error paths, and edge cases for date splitting/billing periods.
- Run `flutter test` and `flutter analyze` before opening a PR.

## Commit & Pull Request Guidelines
Current history follows Conventional Commits, mostly `feat:` and `refactor:` (e.g., `feat: Implement loan split feature with billing days management`).

- Use clear commit prefixes: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`.
- Keep commits scoped to one logical change.
- PRs should include: summary, rationale, impacted layers/files, test evidence, and screenshots/GIFs for UI changes.
- Link related issue/task IDs when applicable.

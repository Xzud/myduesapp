Your current project structure is actually proving why you need strict separation. Right now your repo contains generated/build artifacts mixed with source ownership concerns.

You should NOT branch by:

frontend/
backend/

inside the repo root.

Instead, keep ONE clean Flutter app and separate by architecture layers.

What you should do

Your actual working structure should become:

lib/
  core/
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

Then your branches become:

feature/ui-work
feature/app-logic
feature/backend-infra

NOT permanent branches forever.

Why this matters

If you keep long-lived frontend/backend branches:

You will eventually get:

merge hell
conflicting models
duplicated entities
repository drift
broken imports
stale contracts

Especially with AI agents.

Better approach
Main branch

Always stable.

UI branch

Agent only edits:

presentation/
Logic branch

Agent only edits:

application/
domain/
Infra branch

Agent only edits:

infrastructure/
VERY IMPORTANT

Your uploaded structure includes things that should NEVER be committed:

build/
.dart_tool/
.idea/
.gradle/

These should be gitignored.

Otherwise agents will touch generated files and chaos starts.

Add this .gitignore
.dart_tool/
build/
.idea/
.gradle/
.flutter-plugins
.flutter-plugins-dependencies
.packages
pubspec.lock

(keep pubspec.lock only if app repo policy wants it)

Your AI-agent-safe workflow
Step 1

You define contracts FIRST.

Example:

abstract class DuesRepository {
  Future<List<Due>> getDues();
}
Step 2

Logic agent creates usecases.

Step 3

Infra agent implements repository.

Step 4

UI agent consumes usecases only.

Golden rule

UI must never know:

Firebase
SQLite
REST
Dio
Supabase
HTTP

UI only knows:

GetDuesUseCase
The architecture that scales best for Flutter AI development

Use:

Feature-first Clean Architecture

NOT:

frontend/
backend/
shared/
utils/
services/
helpers/

That old structure becomes spaghetti very fast with autonomous agents.

Your ideal future setup
lib/
  core/
    di/
    errors/
    network/

  features/
    auth/
    dues/
    payments/
    profile/

Each feature:

presentation/
application/
domain/
infrastructure/

That setup lets you safely unleash multiple coding agents simultaneously without them stepping on each other.
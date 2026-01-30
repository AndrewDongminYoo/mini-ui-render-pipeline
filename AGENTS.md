# Repository Guidelines

## Project Structure & Module Organization

- `lib/` contains the public library entrypoint (`lib/render_pipeline.dart`) and implementation in `lib/src/`.
- `lib/src/` is organized by responsibility: `core/` (engine, scheduler, renderer), `models/` (nodes/events/results), `layout/`, and `parser/`.
- `bin/main.dart` is the CLI entrypoint.
- `test/` mirrors the source layout (`core/`, `models/`, `layout/`, `parser/`, `integration/`, `validation/`).
- `example/` includes runnable demos and JSON inputs.
- `docs/` holds design documentation; `PLAN.md`, `README.md`, and `CHANGELOG.md` live at the repo root.

## Build, Test, and Development Commands

- `dart pub get` installs dependencies.
- `dart run build_runner build --delete-conflicting-outputs` runs code generation (JSON serialization).
- `dart test` runs all tests; `dart test test/core/engine_test.dart` runs a single file.
- `dart test --reporter=expanded` enables verbose output.
- `dart analyze` runs static analysis (see `analysis_options.yaml`).
- `dart format --line-length 120 .` formats the codebase.
- If you use `derry`, the repo defines `derry bootstrap`, `derry test`, and `derry format` scripts in `pubspec.yaml`.

## Coding Style & Naming Conventions

- Dart style: 2‑space indentation, line length 120, `camelCase` for variables/functions, `PascalCase` for types.
- Prefer explicit types for public APIs and keep models immutable where practical.
- Use `package:lints/recommended.yaml` (see `analysis_options.yaml`).
- Keep imports sorted (the project uses `import_sorter`).

## Testing Guidelines

- Framework: `package:test`.
- Naming: `*_test.dart` under `test/<area>/` matching the source module.
- Favor unit tests for core/model behavior; use `integration/` for end‑to‑end pipeline scenarios.
- Coverage output (via derry script) is written to `coverage/lcov.info`.

## Commit & Pull Request Guidelines

- Commit messages follow Conventional Commits style (`feat:`, `fix:`, `docs:`, `refactor:`, `build:`), sometimes with emojis—keep the type prefix.
- PRs should include a concise summary, test command(s) run, and any docs/README updates when behavior or CLI output changes.
- Link related issues or tasks when applicable.

## Configuration & Docs

- JSON input/output formats and architecture details are documented in `README.md` and `docs/DESIGN.md`.
- The CLI usage examples in `README.md` should stay in sync with `bin/main.dart` behavior.

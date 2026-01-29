# Development Commands for apr-app-assignment

## Testing

```bash
# Run all tests
dart test

# Run a specific test file
dart test test/mini_ui_test.dart

# Run tests with verbose output
dart test --reporter=expanded
```

## Code Analysis & Formatting

```bash
# Analyze code (uses package:lints/recommended.yaml)
dart analyze

# Format code
dart format .

# Check formatting without applying changes
dart format --output=none --set-exit-if-changed .

# Run Trunk linters (note: Dart linter is disabled in trunk.yaml)
trunk check
trunk fmt
```

## Dependencies & Building

```bash
# Get dependencies
dart pub get

# Build generated files (for json_serializable code generation)
dart run build_runner build

# Watch for changes during development
dart run build_runner watch
```

## Post-Task Workflow

After completing a task:

1. Run `dart analyze` to check for issues
2. Run `dart format .` to format code
3. Run `dart test` to ensure tests pass
4. Run `trunk fmt` for cross-language formatting
5. Commit changes to git

# Development Workflow for apr-app-assignment

## Task Completion Checklist

When completing a coding task:

### 1. Code Quality

- [ ] Code follows naming conventions (PascalCase classes, camelCase functions)
- [ ] Explicit types used for public APIs
- [ ] Complex logic has explanatory comments
- [ ] No unnecessary console logs or debug prints

### 2. Testing

- [ ] All existing tests pass: `dart test`
- [ ] New functionality has unit tests
- [ ] Tests cover both happy path and edge cases

### 3. Code Analysis

- [ ] No linting errors: `dart analyze`
- [ ] Code is properly formatted: `dart format --output=none --set-exit-if-changed .`

### 4. Cross-language Tools

- [ ] Trunk checks pass: `trunk check` (note: Dart linter disabled)
- [ ] Code formatted with Trunk: `trunk fmt`

### 5. Git & Documentation

- [ ] Changes are committed with clear message
- [ ] Public APIs have documentation comments
- [ ] Related PLAN.md or CLAUDE.md updated if needed

## Common Development Tasks

### Running Tests During Development

```bash
dart test --reporter=expanded  # verbose output
dart test test/core/node_tree_test.dart  # specific file
dart run build_runner watch  # watch for code generation
```

### Debugging

- Use `print()` for simple debugging (remove before commit)
- Check test output for error details
- Use `dart analyze` to catch potential issues early

### Adding Dependencies

```bash
dart pub add <package_name>  # adds to pubspec.yaml
dart pub get  # fetch dependencies
```

### Regenerating JSON Serialization Code

```bash
dart run build_runner build  # one-time generation
dart run build_runner watch  # continuous generation during dev
```

## Important Notes

- This is an educational implementation focusing on dirty flag optimization
- Reference the PLAN.md for detailed task specifications (phases 1-6)
- Refer to CLAUDE.md for architectural details and event propagation rules

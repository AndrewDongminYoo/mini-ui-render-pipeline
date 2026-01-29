# Code Style & Conventions for apr-app-assignment

## Naming Conventions

- **Classes**: PascalCase (e.g., `NodeTree`, `Box`, `LayoutCalculator`)
- **Variables/Functions**: camelCase (e.g., `rootNode`, `calculateLayout()`, `isDirty`)
- **Constants**: camelCase or UPPER_SNAKE_CASE depending on context
- **Private members**: Leading underscore (e.g., `_children`, `_parentNode`)

## Type System

- **Use explicit types** for public APIs
- **Use type inference** for internal variables where obvious
- Prefer immutability where possible
- Null-safety: Use non-nullable types by default (`int` not `int?`)

## Code Organization

- One main class per file (except related helpers)
- File naming: snake_case (e.g., `node_tree.dart`, `layout_calculator.dart`)
- Imports organized: dart, package, relative (with blank lines between)

## Documentation

- Public APIs should have documentation comments (`/// ...`)
- Complex logic should have explanatory comments
- No excessive comment bloat for self-evident code

## Linting & Standards

- Uses `package:lints/recommended.yaml`
- **Important**: Dart linter is disabled in trunk.yaml (uses prettier for other files)
- Follow Dart idioms and conventions

## JSON Serialization

- Use `@JsonSerializable()` decorators from `json_annotation`
- Run `dart run build_runner build` to generate code
- Use `.fromJson()` and `.toJson()` methods

# Suggested Commands for apr-app-assignment Project

## Development Workflow Commands

This project uses **derry** (via pubspec.yaml scripts) for common development tasks. Always prefer these commands over direct CLI calls.

### Available Scripts

#### 1. Bootstrap (Project Initialization)

```bash
derry bootstrap
```

**Purpose**: Initializes the project by generating necessary code, sorting imports, and formatting
**What it does**:

- `dart pub get` - Install dependencies
- `derry generate` - Run code generation
- `derry format` - Format and sort imports

**When to use**: First time setup, after pulling changes with new dependencies

#### 2. Generate (Code Generation)

```bash
derry generate
```

**Purpose**: Runs build_runner for code generation
**What it does**:

- `dart run build_runner build --delete-conflicting-outputs`

**When to use**: After adding/modifying JSON serializable classes

#### 3. Format (Code Formatting)

```bash
derry format
```

**Purpose**: Applies automated fixes, sorts imports, and formats the codebase
**What it does**:

- `dart fix --apply` - Apply automated fixes
- `dart format --line-length 120 .` - Format code
- `dart run import_sorter:main -e` - Sort imports

**When to use**: Before committing, after writing new code

#### 4. Test (Run Tests)

```bash
derry test
```

**Purpose**: Runs all tests with coverage
**What it does**:

- `dart test --coverage=coverage --concurrency=4 --test-randomize-ordering-seed=random`

**When to use**: After implementing features, before committing

### Direct Dart Commands (Use only when necessary)

#### Run specific test file

```bash
dart test test/path/to/test_file.dart
```

#### Analyze code

```bash
dart analyze
```

#### Install dependencies

```bash
dart pub get
```

## File Operations - Use Serena MCP Tools

For cost efficiency, always prefer Serena MCP tools over standard tools:

### Reading Files

```bash
mcp__plugin_serena_serena__read_file
```

Instead of: `Read` tool

### Searching Code

```bash
mcp__plugin_serena_serena__search_for_pattern
mcp__plugin_serena_serena__find_symbol
```

Instead of: `Grep` tool

### Editing Files

```bash
mcp__plugin_serena_serena__replace_content (for content replacement)
mcp__plugin_serena_serena__replace_symbol_body (for symbol-level edits)
```

Instead of: `Edit` tool

### Finding Files

```bash
mcp__plugin_serena_serena__find_file
mcp__plugin_serena_serena__list_dir
```

Instead of: `Glob` tool

### Getting Symbol Information

```bash
mcp__plugin_serena_serena__get_symbols_overview
mcp__plugin_serena_serena__find_symbol
mcp__plugin_serena_serena__find_referencing_symbols
```

## Git Workflow

### Before Committing

1. `derry format` - Format code and sort imports
2. `derry test` - Run tests
3. `git add -A`
4. `git commit -m "message"`

### Commit Message Format

Follow Conventional Commits:

- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code restructuring
- `test:` - Test additions/modifications
- `docs:` - Documentation changes
- `chore:` - Build process or auxiliary tool changes

## Project Structure Commands

### View project structure

```bash
mcp__plugin_serena_serena__list_dir
```

### Find specific files

```bash
mcp__plugin_serena_serena__find_file
```

## Important Notes

1. **Always use `derry` commands** for standard development tasks
2. **Use Serena MCP tools** for file operations to minimize costs
3. **Use standard tools** (Read, Edit, Grep, Glob) only when Serena tools are not available or when specifically needed
4. **Run `derry format`** before every commit
5. **Run `derry test`** to ensure all tests pass before committing

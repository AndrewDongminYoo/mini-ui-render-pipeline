# Development Workflow for apr-app-assignment

## Quick Start

### Initial Setup

```bash
derry bootstrap
```

### Development Cycle

1. Write code
2. Format: `derry format`
3. Test: `derry test`
4. Commit

## Tool Usage Guidelines

### File Operations Priority

**ALWAYS prefer Serena MCP tools over standard tools for cost efficiency:**

| Operation           | Serena MCP Tool                                       | Standard Tool (Fallback) |
| ------------------- | ----------------------------------------------------- | ------------------------ |
| Read file           | `mcp__plugin_serena_serena__read_file`                | `Read`                   |
| Edit file (content) | `mcp__plugin_serena_serena__replace_content`          | `Edit`                   |
| Edit file (symbol)  | `mcp__plugin_serena_serena__replace_symbol_body`      | `Edit`                   |
| Search code         | `mcp__plugin_serena_serena__search_for_pattern`       | `Grep`                   |
| Find files          | `mcp__plugin_serena_serena__find_file`                | `Glob`                   |
| List directory      | `mcp__plugin_serena_serena__list_dir`                 | `Glob`                   |
| Get symbols         | `mcp__plugin_serena_serena__get_symbols_overview`     | `Read`                   |
| Find symbol         | `mcp__plugin_serena_serena__find_symbol`              | `Grep`                   |
| Find references     | `mcp__plugin_serena_serena__find_referencing_symbols` | `Grep`                   |

### When to Use Standard Tools

- Shell commands: `Bash` tool
- Git operations: `Bash` tool with git commands
- Running scripts: `Bash` tool with `derry` commands

## Phase 5.2: CLI Interface Implementation

### Current Task

Implement CLI interface in `bin/main.dart`

### Requirements

1. Argument parsing (use `args` package)
2. File input/output handling
3. Error handling and user feedback
4. Help documentation

### Implementation Steps

1. Read current `bin/main.dart` (if exists) using Serena MCP
2. Design CLI argument structure
3. Implement main CLI logic
4. Add error handling
5. Write tests
6. Update documentation

### Testing Commands

```bash
# Run specific CLI test
dart test test/integration/cli_test.dart

# Run all tests
derry test

# Run CLI directly
dart run bin/main.dart [args]
```

## Code Quality Standards

### Before Every Commit

1. **Format**: `derry format`
   - Applies dart fix
   - Formats code
   - Sorts imports

2. **Test**: `derry test`
   - Runs all tests with coverage
   - Randomizes test order

3. **Verify**: `dart analyze`
   - Check for warnings/errors

### Import Sorting

Handled automatically by `derry format`

- 🎯 Dart imports first
- 📦 Package imports second
- 🌎 Project imports last

## Memory Management

### Available Memories

- `project_overview` - Project description and goals
- `codebase_structure` - Architecture and file organization
- `suggested_commands` - Common commands and tool preferences
- `development_workflow` - This file
- `code_style_conventions` - Coding standards

### When to Update Memories

- After major architectural changes
- When adding new commands/scripts
- When establishing new conventions
- After completing major phases

## Current Progress

**Completed Phases:**

- ✅ Phase 1: Core Models (44 tests)
- ✅ Phase 2: Event System (62 tests)
- ✅ Phase 3: Layout Calculation (39 tests)
- ✅ Phase 4: Output Generation (46 tests)
- ✅ Phase 5.1: RenderPipeline (13 tests)

**In Progress:**

- 🔄 Phase 5.2: CLI Interface

**Remaining:**

- ⏳ Phase 6: Testing & Documentation

**Total Tests:** 204 passing

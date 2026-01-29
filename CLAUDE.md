# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mini UI Render Pipeline** - A Dart library that processes UI tree structures and state change events to determine:

- **Structure Changes**: Which nodes had structural modifications
- **Layout/State Recomputation**: Which nodes need recalculation
- **Paint Order**: Final rendering order

This is an educational implementation of a UI rendering system similar to frameworks like Flutter, focusing on dirty flag optimization and incremental updates.

## Development Commands

### Testing

```bash
# Run all tests
dart test

# Run a specific test file
dart test test/mini_ui_test.dart

# Run tests with verbose output
dart test --reporter=expanded
```

### Linting & Formatting

```bash
# Analyze code (uses package:lints/recommended.yaml)
dart analyze

# Format code
dart format .

# Check formatting without applying
dart format --output=none --set-exit-if-changed .

# Run Trunk linters (Dart linter disabled, uses prettier/markdownlint/etc)
trunk check
trunk fmt
```

### Building

```bash
# Get dependencies
dart pub get

# Run as library (no executable defined yet)
# CLI entrypoint will be in bin/main.dart when implemented
```

## Architecture

The system is designed around a **Dirty Flag pattern** for incremental updates, avoiding full tree recalculation on every event.

### Core Flow

```diagram
Event → Mark Target Dirty → Propagate to Related Nodes → Recompute Only Dirty Nodes → Generate Output
```

### Key Modules (Planned in lib/src/)

- **models/** - Data structures
  - `node.dart`: Node abstract class with dirty flags (structure, layout)
  - `event.dart`: Event types (setSize, setPosition, setState, addChild, removeChild, moveChild)
  - `result.dart`: Output format models

- **core/** - Engine components
  - `node_tree.dart`: Tree structure management, node search/add/remove
  - `engine.dart`: Event processing and dirty flag propagation
  - `scheduler.dart`: Collects dirty nodes and determines computation order
  - `renderer.dart`: Generates final JSON output

- **layout/** - Layout computation
  - `calculator.dart`: Per-node-type layout rules (Row, Column, Stack, Box)

- **parser/** - Input processing
  - `json_parser.dart`: Parses input JSON into tree structure

### Node Types & Layout Rules

| Type     | Layout Behavior                     |
| -------- | ----------------------------------- |
| `Box`    | Fixed size (leaf node)              |
| `Row`    | Horizontal: width = sum of children |
| `Column` | Vertical: height = sum of children  |
| `Stack`  | Overlay: size = max of all children |

### Event Impact & Propagation

| Event Type    | Structure Dirty | Layout Dirty              |
| ------------- | --------------- | ------------------------- |
| `setSize`     | No              | Self + Parent + Siblings  |
| `setPosition` | No              | Self only                 |
| `setState`    | No              | Self only                 |
| `addChild`    | Parent + Child  | Parent + Child + Siblings |
| `removeChild` | Parent + Child  | Parent + Siblings         |
| `moveChild`   | Parent          | Parent + All children     |

**Optimization**: Events with no actual change (e.g., setting same size) are detected early and skipped.

### Paint Order

Pre-order DFS traversal: parent rendered before children, siblings in order.

Example tree:

```diagram
R (root)
├── A
│   ├── A1
│   └── A2
└── B
```

Paint Order: `[R, A, A1, A2, B]`

## Testing Strategy

### Test Structure (in test/)

- `models/` - Unit tests for Node and Event models
- `core/` - Tests for engine, scheduler, renderer
- `integration/` - Full pipeline tests with example cases

### Key Test Cases

1. **No-op detection**: Same size change should not trigger recomputation
2. **Size propagation**: Child size change affects parent and siblings
3. **Structure changes**: Add/remove/move child updates structure flags
4. **Nested layouts**: Multi-level tree layout recalculation

Refer to PLAN.md section 9 for detailed test case specifications.

## Input/Output Format

### Input JSON

```json
{
  "tree": {
    "root": "nodeId",
    "nodes": {
      "nodeId": {
        "type": "Row|Column|Box|Stack",
        "children": ["childId"],  // optional
        "size": {"w": 100, "h": 50},  // optional
        "position": {"x": 0, "y": 0},  // optional
        "state": {}  // optional custom state
      }
    }
  },
  "events": [
    {"type": "eventType", "target": "nodeId", ...params}
  ]
}
```

### Output JSON

```json
[
  {
    "afterEvent": 0,
    "recomputeStructure": ["nodeId"],
    "recomputeLayout": ["nodeId"],
    "paintOrder": ["nodeId"]
  }
]
```

## Implementation Phases

See PLAN.md for detailed task breakdown:

1. **Phase 1**: Core models (Node, NodeTree)
2. **Phase 2**: Event system and dirty propagation
3. **Phase 3**: Layout calculation
4. **Phase 4**: Output rendering
5. **Phase 5**: CLI integration
6. **Phase 6**: Testing and documentation

## Code Style Notes

- Uses `package:lints/recommended.yaml` for Dart linting
- Trunk is configured but **Dart linter is disabled** in trunk.yaml
- Follow Dart conventions: camelCase for variables/functions, PascalCase for classes
- Prefer immutability where possible
- Use explicit types for public APIs

## Important Design Decisions

1. **Dirty Flag Types**: Two separate flags (structure vs layout) to distinguish tree changes from property changes
2. **Propagation Order**: Bottom-up for size calculation, top-down for position
3. **recomputeLayout Order**: Direct target first, then propagated nodes (parent, siblings)
4. **Structure Changes**: Only for tree topology changes (add/remove/move), NOT for property changes

Refer to PLAN.md section 8 for detailed rationale.

# apr-app-assignment: Mini UI Render Pipeline

## Project Purpose

A Dart library that implements an educational UI rendering system similar to Flutter's rendering pipeline. It processes UI tree structures and state change events to determine:

- Structure changes (tree topology modifications)
- Layout/state recomputation (which nodes need recalculation)
- Paint order (final rendering sequence)

## Tech Stack

- **Language**: Dart 3.10.7+
- **Package Name**: mini_ui (v1.0.0)
- **Key Dependencies**:
  - `json_annotation`: JSON serialization
  - `json_serializable`: Code generation for JSON
  - `build_runner`: Build system for code generation
- **Development Tools**:
  - `lints`: Dart linting (recommended.yaml)
  - `test`: Unit testing framework
  - `trunk`: Multi-language linter/formatter (Dart linter disabled)

## Core Design Pattern

**Dirty Flag Pattern** - Incremental updates avoiding full tree recalculation on every event.

### Node Types

- `Box`: Fixed size (leaf node)
- `Row`: Horizontal layout - width = sum of children
- `Column`: Vertical layout - height = sum of children
- `Stack`: Overlay - size = max of children

### Paint Order

Pre-order DFS traversal: parent before children, siblings in order.

## Key Design Decisions

1. Two separate dirty flags: structure vs layout
2. Bottom-up propagation for size, top-down for position
3. Early no-op detection for unchanged properties
4. Structure dirty flag only for tree topology changes (add/remove/move), not property changes

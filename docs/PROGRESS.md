# Code Quality Improvement Plan

> Updated: 2026-01-30  
> Based on comprehensive code review of v1.0.0

## Overview

This document tracks code quality improvements identified through static analysis. The codebase is **generally well-designed** with clear separation of concerns, proper dirty flag pattern implementation, and good documentation. The following tasks focus on enhancing robustness, maintainability, and performance.

---

## Priority Improvements

### 🔴 PRIORITY 1: Type Safety - BoxNode Immutability Enforcement

**File**: `lib/src/models/node.dart:203-211`

**Problem**: BoxNode is designed as a leaf node but doesn't enforce this constraint at runtime. Calling `addChild()` will incorrectly add children.

**Solution**:

```dart
class BoxNode extends Node {
  BoxNode(...) : super(type: NodeType.box, children: const []);

  @override
  void addChild(Node child) {
    throw UnsupportedError('BoxNode cannot have children');
  }

  @override
  Node removeChildAt(int index) {
    throw UnsupportedError('BoxNode cannot have children');
  }

  @override
  bool removeChild(Node child) {
    throw UnsupportedError('BoxNode cannot have children');
  }

  @override
  void moveChild(int fromIndex, int toIndex) {
    throw UnsupportedError('BoxNode cannot have children');
  }
}
```

**Impact**: Prevents runtime bugs, enforces design invariants, improves type safety

**Estimated Effort**: 30 minutes (implementation + tests)

---

### 🟡 PRIORITY 2: Code Duplication - Extract Common Parsing Utils

**Files**:

- `lib/src/models/event.dart:210-224, 275-286`
- `lib/src/parser/json_parser.dart:16-28, 136-164`

**Problem**: `_parseSize()`, `_parsePosition()`, and `_nodeTypeToString()` are duplicated across multiple files.

**Solution**: Create `lib/src/utils/parsing_utils.dart`

```dart
// lib/src/utils/parsing_utils.dart
library;

import 'package:mini_ui/src/models/node.dart';

/// Parse a size from JSON map with 'w' and 'h' keys.
Size parseSize(Map<String, dynamic> sizeMap) {
  return Size(
    width: (sizeMap['w'] as num).toDouble(),
    height: (sizeMap['h'] as num).toDouble(),
  );
}

/// Parse a position from JSON map with 'x' and 'y' keys.
Position parsePosition(Map<String, dynamic> positionMap) {
  return Position(
    x: (positionMap['x'] as num).toDouble(),
    y: (positionMap['y'] as num).toDouble(),
  );
}

/// Convert NodeType enum to string representation.
String nodeTypeToString(NodeType type) {
  switch (type) {
    case NodeType.box: return 'Box';
    case NodeType.row: return 'Row';
    case NodeType.column: return 'Column';
    case NodeType.stack: return 'Stack';
  }
}
```

Then refactor both files to use these utilities.

**Impact**: DRY principle adherence, single source of truth for parsing logic

**Estimated Effort**: 45 minutes (extraction + refactoring + tests)

---

### 🟢 PRIORITY 3: Performance - Reduce Tree Traversal Overhead

**File**: `lib/src/core/node_tree.dart:89-102`

**Problem**: `getDirtyStructureNodes()` and `getDirtyLayoutNodes()` each call `getAllNodes()`, resulting in multiple full tree traversals.

**Solution**: Combine into a single traversal

```dart
/// Collect all dirty nodes in one pass.
/// Returns (structureDirty, layoutDirty) node lists.
(List<Node>, List<Node>) getDirtyNodes() {
  final structure = <Node>[];
  final layout = <Node>[];
  if (_root != null) {
    _collectDirtyNodes(_root!, structure, layout);
  }
  return (structure, layout);
}

void _collectDirtyNodes(
  Node node,
  List<Node> structure,
  List<Node> layout,
) {
  if (node.structureDirty) structure.add(node);
  if (node.layoutDirty) layout.add(node);
  for (final child in node.children) {
    _collectDirtyNodes(child, structure, layout);
  }
}

// Keep existing methods for backward compatibility
List<Node> getDirtyStructureNodes() => getDirtyNodes().$1;
List<Node> getDirtyLayoutNodes() => getDirtyNodes().$2;
```

**Impact**: O(2n) → O(n) traversal, significant performance gain on large trees

**Estimated Effort**: 30 minutes (optimization + tests)

---

### 🟡 PRIORITY 4: Configurability - Remove Magic Numbers

**File**: `lib/src/render_pipeline.dart:72`

**Problem**: `maxIterations = 10` is hardcoded, making it difficult to test edge cases or adjust for different use cases.

**Solution**:

```dart
class RenderPipeline {
  /// Maximum iterations for cascading layout recalculation.
  /// Prevents infinite loops in circular dependency scenarios.
  final int maxLayoutIterations;

  /// Creates a render pipeline.
  ///
  /// [maxLayoutIterations] defaults to 10, which is sufficient for most
  /// UI trees. Increase for extremely deep hierarchies.
  RenderPipeline({this.maxLayoutIterations = 10});

  void _recalculateLayoutsCascading(NodeTree tree, Scheduler scheduler) {
    int iteration = 0;

    while (iteration < maxLayoutIterations) {
      // ... existing logic
    }

    if (iteration >= maxLayoutIterations) {
      // Optional: log warning about potential circular dependency
    }
  }
}
```

**Impact**: Testability, configurability, explicit documentation of loop prevention

**Estimated Effort**: 20 minutes (implementation + documentation)

---

### 🟢 PRIORITY 5: Consistency - Standardize Exception Types

**Files**: `lib/src/parser/json_parser.dart`, `lib/src/models/event.dart`

**Problem**: JSON parsing errors use both `FormatException` and `ArgumentError` inconsistently.

**Strategy**:

- **User input errors** (malformed JSON) → `FormatException`
- **Programming errors** (invalid internal state) → `ArgumentError`

**Changes Needed**:

1. In `event.dart:195`:

   ```dart
   // Before
   throw ArgumentError('Unknown node type: $type');

   // After
   throw FormatException('Unknown node type: $type');
   ```

2. In `json_parser.dart:134`:

   ```dart
   // Before
   throw ArgumentError('Unknown node type: $type');

   // After
   throw FormatException('Unknown node type: $type');
   ```

3. Document exception contract in class-level docs

**Impact**: Predictable error handling, easier client integration

**Estimated Effort**: 15 minutes (refactoring + documentation)

---

## Additional Considerations (Not Prioritized)

### Optional: Adopt json_serializable

**Current State**: Manual JSON serialization despite having `json_serializable` in dev_dependencies.

**Options**:

1. **Adopt json_serializable**: Reduce boilerplate, auto-generate serialization
2. **Remove dependency**: Clean up pubspec.yaml if manual approach is intentional

**Trade-offs**:

- Manual = More control, educational value, no build step
- Auto-generated = Less code, fewer bugs, requires build_runner

**Recommendation**: If educational/demonstration purpose → keep manual and remove unused deps. Otherwise, adopt json_serializable for production robustness.

---

## Execution Strategy

1. **Phase 1** (1-2 hours): Address PRIORITY 1-2 (type safety + duplication)
2. **Phase 2** (1 hour): Address PRIORITY 3-4 (performance + configurability)
3. **Phase 3** (30 min): Address PRIORITY 5 (exception consistency)
4. **Testing**: Run full test suite after each phase
5. **Documentation**: Update CHANGELOG.md with improvements

---

## Success Metrics

- ✅ All tests pass with new constraints
- ✅ No regression in existing functionality
- ✅ Code coverage maintained or improved
- ✅ Static analysis (dart analyze) passes with 0 issues

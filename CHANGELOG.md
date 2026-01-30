# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-29

### Added

#### Core Features

- **Node System**: Abstract node types (Box, Row, Column, Stack) with dirty flag tracking
- **Event System**: Six event types for UI state changes
  - `setSize`: Update node dimensions
  - `setPosition`: Update node position
  - `setState`: Update node custom state
  - `addChild`: Add child node to parent
  - `removeChild`: Remove child from parent
  - `moveChild`: Reorder children
- **Engine**: Event processing with intelligent dirty flag propagation
- **Layout Calculator**: Automatic layout computation for all node types
- **Scheduler**: Dirty node collection and layout recalculation
- **Renderer**: JSON output generation with correct recomputeLayout ordering (target → parent → sibling) and pre-order DFS paint order
- **RenderPipeline**: End-to-end integration pipeline with cascading layout updates (fixed-point iteration)
- **JSON Parser**: Bidirectional JSON serialization/deserialization

#### CLI Tool

- Command-line interface for batch processing
- Support for file input/output and stdin/stdout
- Flags: `-i/--input`, `-o/--output`, `-h/--help`, `-v/--version`
- Comprehensive help documentation with examples
- Error handling with user-friendly messages

#### Testing

- 217 comprehensive tests with full coverage
  - Unit tests for all core modules (models, engine, scheduler, renderer, calculator)
  - Integration tests for RenderPipeline with PLAN.md validation
  - CLI integration tests
- All tests passing with randomized order

#### Documentation

- Complete README.md with architecture overview and project context
- Detailed DESIGN.md with 13 Mermaid diagrams documenting final design
- Comprehensive PLAN.md with requirements and specifications
- Usage examples (simple and complex)
- Input/output format specifications
- Development workflow documentation
- API documentation through code comments

#### Development Tools

- Configured linting with `package:lints`
- Import sorting with `import_sorter`
- Code generation support with `build_runner`
- Derry scripts for common tasks
- Git hooks for code quality

### Design Decisions

- **Dirty Flag Pattern**: Two-tier dirty tracking (structure vs layout) to distinguish tree topology changes from property changes
- **recomputeLayout Ordering**: Target-first ordering (directly affected node → parent chain → siblings) as specified in PLAN.md Section 4.5, implemented in `Renderer._collectLayoutNodesInOrder()`
- **Layout Calculation Direction**: Bottom-up size calculation (children → parents) ensures children are computed before parents for accurate container sizing
- **Cascading Updates**: Fixed-point iteration in `RenderPipeline._recalculateLayoutsCascading()` handles nested layout changes where child size affects parent size recursively (max 10 iterations)
- **Pre-order DFS**: Paint order generation ensures parent nodes are rendered before children for correct visual hierarchy
- **No-op Detection**: Early detection in event handlers skips processing when values don't change (e.g., setting same size)

### Performance

- Incremental updates avoid full tree recalculation
- Dirty flag optimization minimizes unnecessary computation
- Bottom-up size calculation ensures efficient single-pass layout
- Cascading updates handle deep tree hierarchies with parent propagation
- No-op detection reduces unnecessary dirty flag propagation

## [1.1.0] - 2026-01-30

### Added

- **BoxNode Immutability**: Runtime enforcement preventing child operations on leaf nodes
  - `addChild()`, `removeChild()`, `removeChildAt()`, `moveChild()` now throw `UnsupportedError`
  - 4 new tests ensuring immutability constraints
- **Configurable Layout Iterations**: `RenderPipeline.maxLayoutIterations` parameter
  - Default value of 10 iterations
  - Configurable for different use cases and testing
  - Improved documentation explaining circular dependency prevention
- **Parsing Utilities**: New `lib/src/utils/parsing_utils.dart` module
  - `parseSize()`: Parse size from JSON map
  - `parsePosition()`: Parse position from JSON map
  - `nodeTypeToString()`: Convert NodeType enum to string

### Changed

- **Performance Optimization**: Single-pass dirty node collection
  - `NodeTree.getDirtyNodes()` now collects both structure and layout dirty nodes in one traversal
  - Improved from O(2n) to O(n) for large trees
  - Backward-compatible API maintained for existing methods
- **Exception Consistency**: Standardized JSON parsing error types
  - `ArgumentError` → `FormatException` for all malformed input errors
  - Clearer semantic distinction between user errors and programming errors
  - Updated all test expectations accordingly

### Removed

- **Unused Dependencies**: Cleaned up `pubspec.yaml`
  - Removed `json_annotation`, `json_serializable`, `build_runner`
  - Removed code generation scripts
  - Simplified bootstrap process

### Refactored

- **Code Duplication**: Extracted common parsing functions
  - Eliminated duplicate implementations in `event.dart` and `json_parser.dart`
  - Single source of truth for parsing logic
  - Easier maintenance and bug fixes

### Documentation

- Updated `docs/PROGRESS.md` with comprehensive code quality improvement plan
- Added detailed rationale and benefits for each improvement
- Included code examples and implementation strategies

### Performance

- Reduced tree traversal overhead by 50% for dirty node collection
- More efficient memory usage with single-pass algorithms

## [Unreleased]

### Planned Features

- Additional layout types (Flex, Grid)
- Animation support
- Constraint-based layouts
- Performance profiling tools
- Web-based visualizer

---

## Version History

- **1.1.0** (2026-01-30): Code quality improvements and performance optimization
- **1.0.0** (2026-01-29): Initial release with full feature set

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
- **Scheduler**: Bottom-up dirty node processing with cascading updates
- **Renderer**: JSON output generation with paint order
- **RenderPipeline**: End-to-end integration pipeline
- **JSON Parser**: Bidirectional JSON serialization/deserialization

#### CLI Tool

- Command-line interface for batch processing
- Support for file input/output and stdin/stdout
- Flags: `-i/--input`, `-o/--output`, `-h/--help`, `-v/--version`
- Comprehensive help documentation with examples
- Error handling with user-friendly messages

#### Testing

- 215 comprehensive tests with full coverage
  - 180 unit tests for all core modules
  - 24 integration tests for RenderPipeline
  - 11 CLI integration tests
- All tests passing with randomized order

#### Documentation

- Complete README.md with architecture overview
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

- **Dirty Flag Pattern**: Two-tier dirty tracking (structure vs layout)
- **Cascading Updates**: Fixed-point iteration for parent propagation
- **Bottom-Up Processing**: Ensures children are processed before parents
- **Pre-order DFS**: Paint order for correct rendering hierarchy
- **No-op Detection**: Skip processing when values don't change

### Performance

- Incremental updates avoid full tree recalculation
- Dirty flag optimization minimizes unnecessary computation
- Bottom-up processing ensures single-pass layout calculation
- Cascading updates handle deep tree hierarchies efficiently

## [Unreleased]

### Planned Features

- Additional layout types (Flex, Grid)
- Animation support
- Constraint-based layouts
- Performance profiling tools
- Web-based visualizer

---

## Version History

- **1.0.0** (2026-01-29): Initial release with full feature set

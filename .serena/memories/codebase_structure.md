# Codebase Structure for apr-app-assignment

## Directory Layout

```diagram
├── lib/src/                         # Main library code
│   ├── mini_ui_base.dart            # Library entry point
│   ├── models/                      # Data structures
│   │   ├── node.dart                # Node abstract class with dirty flags
│   │   └── .gitkeep
│   ├── core/                        # Engine components
│   │   ├── node_tree.dart           # Tree management (implemented)
│   │   └── .gitkeep
│   ├── layout/                      # Layout computation
│   │   └── .gitkeep
│   └── parser/                      # Input processing
│       └── .gitkeep
├── test/                            # Test suite
│   ├── models/                      # Unit tests for models
│   │   ├── node_test.dart           # Node model tests
│   │   └── .gitkeep
│   ├── core/                        # Core component tests
│   │   ├── node_tree_test.dart      # NodeTree tests (implemented)
│   │   └── .gitkeep
│   ├── integration/                 # Full pipeline tests
│   │   └── .gitkeep
│   ├── mini_ui_test.dart            # Main test file
│   └── models/.gitkeep
├── bin/                             # Executable entry points (planned)
├── docs/                            # Documentation
├── examples/                        # Usage examples
├── PLAN.md                          # Detailed implementation plan
├── CLAUDE.md                        # Claude AI instructions
├── pubspec.yaml                     # Dart dependencies
├── analysis_options.yaml            # Linting configuration
└── .gitignore                       # Git ignore rules
```

## Implemented Modules

1. **node.dart** - Node abstract class with dirty flag system
2. **node_tree.dart** - NodeTree for UI hierarchy management

## Planned Modules

- **event.dart** - Event types and handlers
- **engine.dart** - Event processing and dirty flag propagation
- **scheduler.dart** - Collects dirty nodes and computation order
- **renderer.dart** - JSON output generation
- **calculator.dart** - Per-node-type layout rules
- **json_parser.dart** - Input JSON parsing

## Module Dependencies

```diagram
Parser → NodeTree → Engine → Scheduler → Renderer
                  ↓
             LayoutCalculator
```

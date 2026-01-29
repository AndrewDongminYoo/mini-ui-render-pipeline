# Mini UI Render Pipeline

A Dart library that processes UI tree structures and state change events to determine structure changes, layout recomputation, and paint order. This is an educational implementation of a UI rendering system similar to frameworks like Flutter, focusing on dirty flag optimization and incremental updates.

## Features

- ✅ **Event-Driven Updates**: Process UI state changes through a clean event system
- ✅ **Dirty Flag Optimization**: Incremental updates that avoid full tree recalculation
- ✅ **Flexible Layout System**: Support for Row, Column, Stack, and Box layouts
- ✅ **Cascading Updates**: Automatic propagation of size changes up the tree
- ✅ **JSON I/O**: Easy integration with JSON-based UI definitions
- ✅ **CLI Tool**: Command-line interface for batch processing
- ✅ **Comprehensive Tests**: 215 tests with full coverage

## Installation

### As a Library

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  mini_ui: ^1.0.0
```

### As a CLI Tool

```bash
dart pub global activate mini_ui
```

## Quick Start

### Using the CLI

```bash
# Process a JSON file
mini_ui input.json

# Read from stdin, write to file
cat input.json | mini_ui -o output.json

# Explicit input/output
mini_ui --input input.json --output output.json

# Show help
mini_ui --help
```

### Using as a Library

```dart
import 'package:mini_ui/render_pipeline.dart';

void main() {
  final pipeline = RenderPipeline();

  final inputJson = '''
  {
    "tree": {
      "root": "R",
      "nodes": {
        "R": {
          "type": "Row",
          "children": ["A", "B"]
        },
        "A": {
          "type": "Box",
          "size": {"w": 50, "h": 20}
        },
        "B": {
          "type": "Box",
          "size": {"w": 30, "h": 20}
        }
      }
    },
    "events": [
      {
        "type": "setSize",
        "target": "A",
        "newSize": {"w": 100, "h": 30}
      }
    ]
  }
  ''';

  final outputJson = pipeline.processJson(inputJson);
  print(outputJson);
}
```

## Architecture

### Core Components

- **Node Models**: Abstract node types (Box, Row, Column, Stack) with dirty flags
- **Event System**: Six event types for state changes (setSize, setPosition, setState, addChild, removeChild, moveChild)
- **Engine**: Event processing and dirty flag propagation
- **Layout Calculator**: Per-node-type layout computation
- **Scheduler**: Dirty node collection and bottom-up processing order
- **Renderer**: JSON output generation with paint order
- **RenderPipeline**: End-to-end integration with cascading updates

### Layout Rules

| Node Type  | Layout Behavior                                                            |
| ---------- | -------------------------------------------------------------------------- |
| **Box**    | Fixed size (leaf node)                                                     |
| **Row**    | Horizontal: `width = sum(children.width)`, `height = max(children.height)` |
| **Column** | Vertical: `height = sum(children.height)`, `width = max(children.width)`   |
| **Stack**  | Overlay: `size = max(children.size)` for both dimensions                   |

### Event Impact

| Event         | Structure Dirty | Layout Dirty              |
| ------------- | --------------- | ------------------------- |
| `setSize`     | No              | Self + Parent + Siblings  |
| `setPosition` | No              | Self only                 |
| `setState`    | No              | Self only                 |
| `addChild`    | Parent + Child  | Parent + Child + Siblings |
| `removeChild` | Parent + Child  | Parent + Siblings         |
| `moveChild`   | Parent          | Parent + All children     |

## Input/Output Format

### Input JSON

```json
{
  "tree": {
    "root": "nodeId",
    "nodes": {
      "nodeId": {
        "type": "Row|Column|Box|Stack",
        "children": ["childId"],
        "size": { "w": 100, "h": 50 },
        "position": { "x": 0, "y": 0 },
        "state": { "key": "value" }
      }
    }
  },
  "events": [
    {
      "type": "setSize",
      "target": "nodeId",
      "newSize": { "w": 150, "h": 60 }
    }
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

## Development

### Setup

```bash
# Clone repository
git clone https://github.com/your-org/mini-ui.git
cd mini-ui

# Install dependencies and setup
derry bootstrap
```

### Available Commands

```bash
# Run tests
derry test

# Format code
derry format

# Generate code
derry generate

# Run specific test
dart test test/path/to/test.dart

# Run CLI locally
dart run bin/main.dart input.json
```

### Project Structure

```log
lib/
├── src/
│   ├── core/          # Engine, NodeTree, Scheduler, Renderer
│   ├── models/        # Node, Event, Result models
│   ├── layout/        # Layout calculator
│   ├── parser/        # JSON parser
│   └── render_pipeline.dart  # Main pipeline
├── render_pipeline.dart  # Public API exports
bin/
└── main.dart          # CLI entrypoint
test/
├── models/            # Unit tests
├── core/              # Unit tests
├── layout/            # Unit tests
├── parser/            # Unit tests
└── integration/       # Integration tests
```

## Testing

The project has comprehensive test coverage with 215 tests:

- **Unit Tests**: 180 tests covering all core modules
- **Integration Tests**: 24 tests for RenderPipeline
- **CLI Tests**: 11 tests for command-line interface

Run tests with:

```bash
derry test
```

## Design Decisions

### Dirty Flag Pattern

Uses two separate dirty flags:

- **Structure Dirty**: Tree topology changes (add/remove/move nodes)
- **Layout Dirty**: Property changes requiring size recalculation

### Cascading Updates

When a child's size changes, the parent is automatically marked dirty through fixed-point iteration, ensuring all affected ancestors are recalculated.

### Bottom-Up Processing

Layout recalculation processes nodes from deepest to shallowest, ensuring child sizes are available when computing parent sizes.

### Paint Order

Pre-order DFS traversal ensures parents are painted before children, and siblings are painted in order.

## Contributing

This is an educational project. Contributions are welcome for:

- Additional layout types
- Performance optimizations
- Documentation improvements
- Bug fixes

## License

MIT License - see LICENSE file for details.

## Acknowledgments

Inspired by Flutter's rendering pipeline and the Fiber architecture in React.

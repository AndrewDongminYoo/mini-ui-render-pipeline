/// Utility functions for parsing JSON structures.
library;

// 🌎 Project imports:
import 'package:mini_ui/src/models/node.dart';

/// Parse a size from JSON map with 'w' and 'h' keys.
///
/// Example:
/// ```dart
/// final size = parseSize({'w': 100, 'h': 50});
/// ```
Size parseSize(Map<String, dynamic> sizeMap) {
  return Size(
    width: (sizeMap['w'] as num).toDouble(),
    height: (sizeMap['h'] as num).toDouble(),
  );
}

/// Parse a position from JSON map with 'x' and 'y' keys.
///
/// Example:
/// ```dart
/// final position = parsePosition({'x': 10, 'y': 20});
/// ```
Position parsePosition(Map<String, dynamic> positionMap) {
  return Position(
    x: (positionMap['x'] as num).toDouble(),
    y: (positionMap['y'] as num).toDouble(),
  );
}

/// Convert NodeType enum to string representation.
///
/// Example:
/// ```dart
/// final typeName = nodeTypeToString(NodeType.box); // 'Box'
/// ```
String nodeTypeToString(NodeType type) {
  switch (type) {
    case NodeType.box:
      return 'Box';
    case NodeType.row:
      return 'Row';
    case NodeType.column:
      return 'Column';
    case NodeType.stack:
      return 'Stack';
  }
}

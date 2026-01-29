import 'package:mini_ui/src/models/node.dart';

/// Calculator for computing node layouts based on their type.
class LayoutCalculator {
  /// Calculate the layout size for a node based on its type and children.
  /// Returns the computed size, or null if size cannot be calculated.
  Size? calculateLayout(Node node) {
    switch (node.type) {
      case NodeType.box:
        return _calculateBoxLayout(node);
      case NodeType.row:
        return _calculateRowLayout(node);
      case NodeType.column:
        return _calculateColumnLayout(node);
      case NodeType.stack:
        return _calculateStackLayout(node);
    }
  }

  /// Box nodes have fixed size (use existing size).
  /// Returns null if size is not set.
  Size? _calculateBoxLayout(Node node) {
    return node.size;
  }

  /// Row nodes arrange children horizontally.
  /// Width = sum of children's widths.
  /// Height = max of children's heights.
  /// Returns null if any child has no size.
  Size? _calculateRowLayout(Node node) {
    if (node.children.isEmpty) {
      return Size(width: 0, height: 0);
    }

    double totalWidth = 0;
    double maxHeight = 0;

    for (final child in node.children) {
      if (child.size == null) {
        return null; // Cannot calculate if any child has no size
      }
      totalWidth += child.size!.width;
      if (child.size!.height > maxHeight) {
        maxHeight = child.size!.height;
      }
    }

    return Size(width: totalWidth, height: maxHeight);
  }

  /// Column nodes arrange children vertically.
  /// Width = max of children's widths.
  /// Height = sum of children's heights.
  /// Returns null if any child has no size.
  Size? _calculateColumnLayout(Node node) {
    if (node.children.isEmpty) {
      return Size(width: 0, height: 0);
    }

    double maxWidth = 0;
    double totalHeight = 0;

    for (final child in node.children) {
      if (child.size == null) {
        return null; // Cannot calculate if any child has no size
      }
      if (child.size!.width > maxWidth) {
        maxWidth = child.size!.width;
      }
      totalHeight += child.size!.height;
    }

    return Size(width: maxWidth, height: totalHeight);
  }

  /// Stack nodes overlay children.
  /// Width = max of children's widths.
  /// Height = max of children's heights.
  /// Returns null if any child has no size.
  Size? _calculateStackLayout(Node node) {
    if (node.children.isEmpty) {
      return Size(width: 0, height: 0);
    }

    double maxWidth = 0;
    double maxHeight = 0;

    for (final child in node.children) {
      if (child.size == null) {
        return null; // Cannot calculate if any child has no size
      }
      if (child.size!.width > maxWidth) {
        maxWidth = child.size!.width;
      }
      if (child.size!.height > maxHeight) {
        maxHeight = child.size!.height;
      }
    }

    return Size(width: maxWidth, height: maxHeight);
  }

  /// Recalculate layout for a node and update its size.
  /// Returns true if the size was updated, false otherwise.
  bool recalculateLayout(Node node) {
    final newSize = calculateLayout(node);

    // If we couldn't calculate (e.g., missing child sizes), don't update
    if (newSize == null) {
      return false;
    }

    // Update only if size actually changed
    if (node.size != newSize) {
      node.size = newSize;
      return true;
    }

    return false;
  }

  /// Recalculate layouts for multiple nodes in bottom-up order.
  /// This ensures child sizes are calculated before parent sizes.
  /// Returns the list of nodes whose sizes were updated.
  List<Node> recalculateLayouts(List<Node> nodes) {
    final updated = <Node>[];

    // Process in reverse order (bottom-up: children before parents)
    // This assumes nodes are provided in a top-down order
    for (final node in nodes.reversed) {
      if (recalculateLayout(node)) {
        updated.add(node);
      }
    }

    return updated.reversed.toList();
  }
}

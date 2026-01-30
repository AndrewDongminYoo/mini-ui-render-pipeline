/// Represents a 2D size with width and height.
class Size {
  final double width;
  final double height;

  Size({required this.width, required this.height});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Size && runtimeType == other.runtimeType && width == other.width && height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  @override
  String toString() => 'Size($width, $height)';

  /// Creates a copy of this size with optional width/height override.
  Size copyWith({double? width, double? height}) {
    return Size(width: width ?? this.width, height: height ?? this.height);
  }
}

/// Represents a 2D position with x and y coordinates.
class Position {
  final double x;
  final double y;

  Position({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Position && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Position($x, $y)';

  /// Creates a copy of this position with optional x/y override.
  Position copyWith({double? x, double? y}) {
    return Position(x: x ?? this.x, y: y ?? this.y);
  }
}

/// Enum for node types.
enum NodeType { box, row, column, stack }

/// Base class for all UI nodes.
abstract class Node {
  /// Unique identifier for this node.
  final String id;

  /// Type of this node.
  final NodeType type;

  /// Parent node reference.
  Node? parent;

  /// Child nodes.
  final List<Node> children;

  /// Size of this node.
  Size? size;

  /// Position of this node.
  Position? position;

  /// Custom state for this node.
  final Map<String, dynamic> state;

  /// Whether this node's structure is dirty and needs recalculation.
  bool structureDirty;

  /// Whether this node's layout is dirty and needs recalculation.
  bool layoutDirty;

  Node({
    required this.id,
    required this.type,
    this.parent,
    List<Node>? children,
    this.size,
    this.position,
    Map<String, dynamic>? state,
    this.structureDirty = false,
    this.layoutDirty = false,
  }) : children = children ?? [],
       state = state ?? {} {
    // Set parent reference for all children
    for (final child in this.children) {
      child.parent = this;
    }
  }

  /// Mark this node's structure as dirty.
  void markStructureDirty() {
    structureDirty = true;
  }

  /// Mark this node's layout as dirty.
  void markLayoutDirty() {
    layoutDirty = true;
  }

  /// Clear dirty flags.
  void clearDirtyFlags() {
    structureDirty = false;
    layoutDirty = false;
  }

  /// Add a child node.
  void addChild(Node child) {
    child.parent = this;
    children.add(child);
  }

  /// Remove a child node by index.
  Node removeChildAt(int index) {
    final child = children.removeAt(index);
    child.parent = null;
    return child;
  }

  /// Remove a child node by reference.
  bool removeChild(Node child) {
    if (children.remove(child)) {
      child.parent = null;
      return true;
    }
    return false;
  }

  /// Move a child from one position to another.
  void moveChild(int fromIndex, int toIndex) {
    final child = children.removeAt(fromIndex);
    children.insert(toIndex, child);
  }

  /// Get the index of a child node.
  int getChildIndex(Node child) {
    return children.indexOf(child);
  }

  /// Find a child node by ID.
  Node? findChild(String childId) {
    for (final child in children) {
      if (child.id == childId) {
        return child;
      }
    }
    return null;
  }

  /// Recursively find a descendant node by ID.
  Node? findDescendant(String descendantId) {
    for (final child in children) {
      if (child.id == descendantId) {
        return child;
      }
      final result = child.findDescendant(descendantId);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Check if this node is a leaf (no children).
  bool get isLeaf => children.isEmpty;

  /// Check if this node is a container (has children or can have children).
  bool get isContainer => type != NodeType.box;

  @override
  String toString() {
    return '${type.name.toUpperCase()}($id, size: $size, children: ${children.length})';
  }
}

/// A box node (leaf node with fixed size).
class BoxNode extends Node {
  BoxNode({
    required super.id,
    super.size,
    super.position,
    super.state,
    super.structureDirty,
    super.layoutDirty,
  }) : super(type: NodeType.box, children: []);

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

/// A row node (horizontal layout container).
class RowNode extends Node {
  RowNode({
    required super.id,
    super.children,
    super.size,
    super.position,
    super.state,
    super.structureDirty,
    super.layoutDirty,
  }) : super(type: NodeType.row);
}

/// A column node (vertical layout container).
class ColumnNode extends Node {
  ColumnNode({
    required super.id,
    super.children,
    super.size,
    super.position,
    super.state,
    super.structureDirty,
    super.layoutDirty,
  }) : super(type: NodeType.column);
}

/// A stack node (overlay layout container).
class StackNode extends Node {
  StackNode({
    required super.id,
    super.children,
    super.size,
    super.position,
    super.state,
    super.structureDirty,
    super.layoutDirty,
  }) : super(type: NodeType.stack);
}

/// Factory function to create a node based on type string.
Node createNode({
  required String id,
  required String type,
  Size? size,
  Position? position,
  List<Node>? children,
  Map<String, dynamic>? state,
}) {
  switch (type.toLowerCase()) {
    case 'box':
      return BoxNode(id: id, size: size, position: position, state: state);
    case 'row':
      return RowNode(
        id: id,
        children: children,
        size: size,
        position: position,
        state: state,
      );
    case 'column':
      return ColumnNode(
        id: id,
        children: children,
        size: size,
        position: position,
        state: state,
      );
    case 'stack':
      return StackNode(
        id: id,
        children: children,
        size: size,
        position: position,
        state: state,
      );
    default:
      throw FormatException('Unknown node type: $type');
  }
}

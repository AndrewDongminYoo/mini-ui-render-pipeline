import '../models/node.dart';

/// Manages the tree structure of UI nodes.
class NodeTree {
  /// Root node of the tree.
  Node? _root;

  /// Map of all nodes by their ID for quick lookup.
  final Map<String, Node> _nodeMap = {};

  /// Get the root node.
  Node? get root => _root;

  /// Set the root node.
  set root(Node? node) {
    _root = node;
    _nodeMap.clear();
    if (node != null) {
      _buildNodeMap(node);
    }
  }

  /// Initialize tree with a root node and rebuild the node map.
  void initialize(Node rootNode) {
    root = rootNode;
  }

  /// Find a node by ID in the tree.
  Node? findNode(String nodeId) {
    return _nodeMap[nodeId];
  }

  /// Add a node to the tree (already parented).
  /// Useful for dynamically adding nodes.
  void addNode(Node node) {
    if (_nodeMap.containsKey(node.id)) {
      throw ArgumentError('Node with ID ${node.id} already exists');
    }
    _nodeMap[node.id] = node;
  }

  /// Remove a node from the tree and its subtree.
  void removeNode(String nodeId) {
    final node = _nodeMap.remove(nodeId);
    if (node != null) {
      // Remove from parent
      node.parent?.removeChild(node);
      // Remove all descendants
      _removeDescendants(node);
    }
  }

  /// Remove all descendants of a node from the map.
  void _removeDescendants(Node node) {
    for (final child in node.children) {
      _nodeMap.remove(child.id);
      _removeDescendants(child);
    }
  }

  /// Get all nodes in the tree (pre-order DFS).
  List<Node> getAllNodes() {
    final nodes = <Node>[];
    if (_root != null) {
      _preOrderTraversal(_root!, nodes);
    }
    return nodes;
  }

  /// Get paint order (pre-order DFS).
  /// Returns list of node IDs in paint order.
  List<String> getPaintOrder() {
    final order = <String>[];
    if (_root != null) {
      _preOrderTraversalIds(_root!, order);
    }
    return order;
  }

  /// Perform pre-order DFS traversal (parent before children).
  void _preOrderTraversal(Node node, List<Node> result) {
    result.add(node);
    for (final child in node.children) {
      _preOrderTraversal(child, result);
    }
  }

  /// Perform pre-order DFS traversal collecting node IDs.
  void _preOrderTraversalIds(Node node, List<String> result) {
    result.add(node.id);
    for (final child in node.children) {
      _preOrderTraversalIds(child, result);
    }
  }

  /// Get all dirty structure nodes (pre-order).
  List<Node> getDirtyStructureNodes() {
    return getAllNodes().where((node) => node.structureDirty).toList();
  }

  /// Get all dirty layout nodes (pre-order).
  List<Node> getDirtyLayoutNodes() {
    return getAllNodes().where((node) => node.layoutDirty).toList();
  }

  /// Get all dirty nodes (both structure and layout).
  List<Node> getAllDirtyNodes() {
    return getAllNodes().where((node) => node.structureDirty || node.layoutDirty).toList();
  }

  /// Clear all dirty flags in the tree.
  void clearAllDirtyFlags() {
    for (final node in getAllNodes()) {
      node.clearDirtyFlags();
    }
  }

  /// Validate tree structure (parent-child consistency).
  /// Returns a list of error messages. Empty if valid.
  List<String> validate() {
    final errors = <String>[];

    // Check root has no parent
    if (_root?.parent != null) {
      errors.add('Root node has a parent');
    }

    // Check all nodes are reachable from root
    final reachable = <String>{};
    if (_root != null) {
      _markReachable(_root!, reachable);
    }

    for (final nodeId in _nodeMap.keys) {
      if (!reachable.contains(nodeId)) {
        errors.add('Node $nodeId is not reachable from root');
      }
    }

    // Check parent-child consistency
    for (final node in getAllNodes()) {
      for (final child in node.children) {
        if (child.parent != node) {
          errors.add(
            'Parent-child mismatch: ${child.id} parent is ${child.parent?.id}, expected ${node.id}',
          );
        }
      }
    }

    return errors;
  }

  /// Mark all nodes reachable from a node.
  void _markReachable(Node node, Set<String> reachable) {
    reachable.add(node.id);
    for (final child in node.children) {
      _markReachable(child, reachable);
    }
  }

  /// Build the node map from the tree structure.
  void _buildNodeMap(Node node) {
    _nodeMap[node.id] = node;
    for (final child in node.children) {
      _buildNodeMap(child);
    }
  }

  /// Get sibling nodes of a given node.
  List<Node> getSiblings(Node node) {
    final parent = node.parent;
    if (parent == null) {
      return [];
    }
    return parent.children.where((n) => n.id != node.id).toList();
  }

  /// Get the depth of a node (root depth = 0).
  int getNodeDepth(Node node) {
    int depth = 0;
    Node? current = node;
    while (current?.parent != null) {
      depth++;
      current = current!.parent;
    }
    return depth;
  }

  /// Get all ancestors of a node (from immediate parent to root).
  List<Node> getAncestors(Node node) {
    final ancestors = <Node>[];
    Node? current = node.parent;
    while (current != null) {
      ancestors.add(current);
      current = current.parent;
    }
    return ancestors;
  }

  /// Get all descendants of a node (excluding the node itself).
  List<Node> getDescendants(Node node) {
    final descendants = <Node>[];
    _collectDescendants(node, descendants);
    return descendants;
  }

  /// Collect all descendants into a list.
  void _collectDescendants(Node node, List<Node> descendants) {
    for (final child in node.children) {
      descendants.add(child);
      _collectDescendants(child, descendants);
    }
  }

  /// Utility to print tree structure (for debugging).
  String debugPrint() {
    if (_root == null) {
      return 'Empty tree';
    }
    final buffer = StringBuffer();
    _debugPrintNode(_root!, buffer, '', true);
    return buffer.toString();
  }

  /// Debug print a node and its children.
  void _debugPrintNode(
    Node node,
    StringBuffer buffer,
    String indent,
    bool isLast,
  ) {
    buffer.write(indent);
    buffer.write(isLast ? '└── ' : '├── ');
    buffer.write('${node.type.name.toUpperCase()}(${node.id})');
    if (node.size != null) {
      buffer.write(' [${node.size!.width}x${node.size!.height}]');
    }
    if (node.structureDirty || node.layoutDirty) {
      buffer.write(' [DIRTY:');
      if (node.structureDirty) buffer.write('S');
      if (node.layoutDirty) buffer.write('L');
      buffer.write(']');
    }
    buffer.writeln();

    final children = node.children;
    for (int i = 0; i < children.length; i++) {
      final isLastChild = i == children.length - 1;
      final childIndent = indent + (isLast ? '    ' : '│   ');
      _debugPrintNode(children[i], buffer, childIndent, isLastChild);
    }
  }
}

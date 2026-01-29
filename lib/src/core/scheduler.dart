// 🌎 Project imports:
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/layout/calculator.dart';
import 'package:mini_ui/src/models/node.dart';

/// Scheduler for collecting dirty nodes and determining computation order.
class Scheduler {
  /// The node tree being managed.
  final NodeTree tree;

  /// The layout calculator for computing node sizes.
  final LayoutCalculator calculator;

  Scheduler(this.tree, this.calculator);

  /// Collect all dirty structure nodes in pre-order.
  List<String> collectDirtyStructureNodes() {
    final dirtyNodes = tree.getDirtyStructureNodes();
    return dirtyNodes.map((node) => node.id).toList();
  }

  /// Collect all dirty layout nodes in a bottom-up order.
  /// This ensures children are processed before parents.
  List<String> collectDirtyLayoutNodes() {
    final dirtyNodes = tree.getDirtyLayoutNodes();

    // Sort by depth (descending) to ensure bottom-up processing
    dirtyNodes.sort((a, b) {
      final depthA = tree.getNodeDepth(a);
      final depthB = tree.getNodeDepth(b);
      return depthB.compareTo(depthA); // Deeper nodes first
    });

    return dirtyNodes.map((node) => node.id).toList();
  }

  /// Recalculate layouts for all dirty layout nodes.
  /// Returns the list of node IDs whose layouts were actually updated.
  List<String> recalculateDirtyLayouts() {
    final dirtyNodes = tree.getDirtyLayoutNodes();

    // Sort by depth (descending) for bottom-up processing
    dirtyNodes.sort((a, b) {
      final depthA = tree.getNodeDepth(a);
      final depthB = tree.getNodeDepth(b);
      return depthB.compareTo(depthA);
    });

    final updated = <String>[];

    for (final node in dirtyNodes) {
      if (calculator.recalculateLayout(node)) {
        updated.add(node.id);
      }
    }

    return updated;
  }

  /// Get the computation order for dirty layout nodes.
  /// Returns nodes in bottom-up order (children before parents).
  List<Node> getComputationOrder() {
    final dirtyNodes = tree.getDirtyLayoutNodes();

    // Sort by depth (descending) for bottom-up processing
    dirtyNodes.sort((a, b) {
      final depthA = tree.getNodeDepth(a);
      final depthB = tree.getNodeDepth(b);
      return depthB.compareTo(depthA);
    });

    return dirtyNodes;
  }

  /// Process all dirty nodes: structure and layout.
  /// Returns a summary of processed nodes.
  ProcessingSummary processAllDirty() {
    final structureNodes = collectDirtyStructureNodes();
    final layoutNodes = collectDirtyLayoutNodes();
    final updatedLayouts = recalculateDirtyLayouts();

    return ProcessingSummary(
      structureNodes: structureNodes,
      layoutNodes: layoutNodes,
      updatedLayouts: updatedLayouts,
    );
  }
}

/// Summary of node processing results.
class ProcessingSummary {
  /// Nodes marked as structure dirty.
  final List<String> structureNodes;

  /// Nodes marked as layout dirty (in computation order).
  final List<String> layoutNodes;

  /// Nodes whose layouts were actually recalculated.
  final List<String> updatedLayouts;

  ProcessingSummary({
    required this.structureNodes,
    required this.layoutNodes,
    required this.updatedLayouts,
  });

  @override
  String toString() {
    return 'ProcessingSummary('
        'structure: ${structureNodes.length}, '
        'layout: ${layoutNodes.length}, '
        'updated: ${updatedLayouts.length})';
  }
}

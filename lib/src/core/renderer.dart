// 🌎 Project imports:
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/core/scheduler.dart';
import 'package:mini_ui/src/models/result.dart';

/// Renderer for generating output after event processing.
class Renderer {
  /// The node tree being managed.
  final NodeTree tree;

  /// The scheduler for dirty node processing.
  final Scheduler scheduler;

  Renderer(this.tree, this.scheduler);

  /// Generate result after processing an event.
  /// This should be called after the event has been processed and
  /// dirty flags have been set.
  ///
  /// [eventTargetId] is the ID of the node that was directly affected by the event.
  /// This is used to determine the correct order for recomputeLayout.
  EventResult generateResult(int eventIndex, String eventTargetId) {
    // Collect dirty nodes
    final structureNodes = scheduler.collectDirtyStructureNodes();
    final layoutNodes = _collectLayoutNodesInOrder(eventTargetId);

    // Get paint order (pre-order DFS)
    final paintOrder = tree.getPaintOrder();

    return EventResult(
      afterEvent: eventIndex,
      recomputeStructure: structureNodes,
      recomputeLayout: layoutNodes,
      paintOrder: paintOrder,
    );
  }

  /// Collect layout dirty nodes in the correct order as per PLAN.md 4.5:
  /// 1. Directly affected node (event target)
  /// 2. Nodes propagated upward (parents)
  /// 3. Sibling nodes
  List<String> _collectLayoutNodesInOrder(String eventTargetId) {
    // Collect all dirty layout nodes
    final dirtyNodes = tree.getAllNodes().where((node) => node.layoutDirty).map((node) => node.id).toSet();

    final result = <String>[];
    final processed = <String>{};

    // 1. Add target node first (if dirty)
    if (dirtyNodes.contains(eventTargetId)) {
      result.add(eventTargetId);
      processed.add(eventTargetId);
    }

    // 2. Add parents of target (upward propagation)
    final target = tree.findNode(eventTargetId);
    if (target != null) {
      var parent = target.parent;
      while (parent != null) {
        if (dirtyNodes.contains(parent.id) && !processed.contains(parent.id)) {
          result.add(parent.id);
          processed.add(parent.id);
        }
        parent = parent.parent;
      }
    }

    // 3. Add siblings of target
    if (target?.parent != null) {
      for (final sibling in target!.parent!.children) {
        if (sibling.id != eventTargetId && dirtyNodes.contains(sibling.id) && !processed.contains(sibling.id)) {
          result.add(sibling.id);
          processed.add(sibling.id);
        }
      }
    }

    // 4. Add any remaining dirty nodes (edge cases)
    for (final nodeId in dirtyNodes) {
      if (!processed.contains(nodeId)) {
        result.add(nodeId);
      }
    }

    return result;
  }

  /// Convert results to JSON array.
  List<Map<String, dynamic>> resultsToJson(List<EventResult> results) {
    return results.map((result) => result.toJson()).toList();
  }

  /// Convert results from JSON array.
  List<EventResult> resultsFromJson(List<Map<String, dynamic>> json) {
    return json.map(EventResult.fromJson).toList();
  }
}

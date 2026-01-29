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
  EventResult generateResult(int eventIndex) {
    // Collect dirty nodes
    final structureNodes = scheduler.collectDirtyStructureNodes();
    final layoutNodes = scheduler.collectDirtyLayoutNodes();

    // Get paint order (pre-order DFS)
    final paintOrder = tree.getPaintOrder();

    return EventResult(
      afterEvent: eventIndex,
      recomputeStructure: structureNodes,
      recomputeLayout: layoutNodes,
      paintOrder: paintOrder,
    );
  }

  /// Generate results for multiple events.
  /// Assumes events have already been processed.
  List<EventResult> generateResults(int eventCount) {
    final results = <EventResult>[];

    for (int i = 0; i < eventCount; i++) {
      results.add(generateResult(i));
    }

    return results;
  }

  /// Convert results to JSON array.
  List<Map<String, dynamic>> resultsToJson(List<EventResult> results) {
    return results.map((result) => result.toJson()).toList();
  }

  /// Convert results from JSON array.
  List<EventResult> resultsFromJson(List<dynamic> json) {
    return json
        .map((item) => EventResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

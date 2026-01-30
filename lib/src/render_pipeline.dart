// 🎯 Dart imports:
import 'dart:convert';

// 🌎 Project imports:
import 'package:mini_ui/src/core/engine.dart';
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/core/renderer.dart';
import 'package:mini_ui/src/core/scheduler.dart';
import 'package:mini_ui/src/layout/calculator.dart';
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/result.dart';
import 'package:mini_ui/src/parser/json_parser.dart';

/// Main pipeline for processing UI events and generating render results.
class RenderPipeline {
  /// Process input JSON and return output JSON results.
  String processJson(String inputJson) {
    final results = process(inputJson);
    return jsonEncode(results.map((r) => r.toJson()).toList());
  }

  /// Process input JSON and return EventResult objects.
  List<EventResult> process(String inputJson) {
    // Parse input
    final parser = JsonParser();
    final input = parser.parse(inputJson);

    // Initialize tree
    final tree = NodeTree();
    tree.initialize(input.root);

    // Set up pipeline components
    final calculator = LayoutCalculator();
    final scheduler = Scheduler(tree, calculator);
    final engine = Engine(tree);
    final renderer = Renderer(tree, scheduler);

    // Process each event and collect results
    final results = <EventResult>[];
    for (int i = 0; i < input.events.length; i++) {
      final event = input.events[i];

      // Process event (marks nodes dirty)
      engine.processEvent(event);

      // Recalculate layouts for dirty nodes (cascading updates)
      // Keep recalculating until no more changes (fixed-point iteration)
      _recalculateLayoutsCascading(tree, scheduler);

      // Generate result
      final result = renderer.generateResult(i, event.targetId);
      results.add(result);

      // Clear dirty flags for next event
      tree.clearAllDirtyFlags();
    }

    return results;
  }

  /// Process input from parsed components and return results.
  List<EventResult> processFromComponents({
    required NodeTree tree,
    required List<Event> events,
  }) {
    final calculator = LayoutCalculator();
    final scheduler = Scheduler(tree, calculator);
    final engine = Engine(tree);
    final renderer = Renderer(tree, scheduler);

    final results = <EventResult>[];
    for (int i = 0; i < events.length; i++) {
      final event = events[i];

      // Process event
      engine.processEvent(event);

      // Recalculate layouts (cascading)
      _recalculateLayoutsCascading(tree, scheduler);

      // Generate result
      final result = renderer.generateResult(i, event.targetId);
      results.add(result);

      // Clear dirty flags
      tree.clearAllDirtyFlags();
    }

    return results;
  }

  /// Recalculate layouts with cascading updates.
  /// If a node's size changes, mark its parent dirty and recalculate again.
  /// Continue until no more changes (fixed-point iteration).
  void _recalculateLayoutsCascading(NodeTree tree, Scheduler scheduler) {
    const maxIterations = 10; // Prevent infinite loops
    int iteration = 0;

    while (iteration < maxIterations) {
      final updated = scheduler.recalculateDirtyLayouts();

      if (updated.isEmpty) {
        break; // No more changes
      }

      // Mark parents of updated nodes dirty for next iteration
      for (final nodeId in updated) {
        final node = tree.findNode(nodeId);
        if (node != null && node.parent != null) {
          node.parent!.markLayoutDirty();
        }
      }

      iteration++;
    }
  }
}

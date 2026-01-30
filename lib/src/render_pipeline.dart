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
  /// Maximum iterations for cascading layout recalculation.
  ///
  /// This prevents infinite loops in circular dependency scenarios.
  /// The default value of 10 is sufficient for most UI trees.
  /// Increase for extremely deep hierarchies.
  final int maxLayoutIterations;

  /// Creates a render pipeline.
  ///
  /// [maxLayoutIterations] defaults to 10. This is the maximum number of
  /// iterations for cascading layout updates before stopping to prevent
  /// infinite loops. For most UI trees, 10 iterations is more than sufficient.
  RenderPipeline({this.maxLayoutIterations = 10});

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
  ///
  /// If a node's size changes, mark its parent dirty and recalculate again.
  /// Continue until no more changes (fixed-point iteration).
  ///
  /// Uses [maxLayoutIterations] to prevent infinite loops in case of
  /// circular dependencies or configuration errors.
  void _recalculateLayoutsCascading(NodeTree tree, Scheduler scheduler) {
    int iteration = 0;

    while (iteration < maxLayoutIterations) {
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

    // Note: If iteration reaches maxLayoutIterations, there may be a
    // circular dependency or extremely deep hierarchy. This is not an
    // error, but the layout may not be fully resolved.
  }
}

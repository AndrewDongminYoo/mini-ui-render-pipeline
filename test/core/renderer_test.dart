// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/core/engine.dart';
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/core/renderer.dart';
import 'package:mini_ui/src/core/scheduler.dart';
import 'package:mini_ui/src/layout/calculator.dart';
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/node.dart';
import 'package:mini_ui/src/models/result.dart';

void main() {
  group('EventResult', () {
    test('should create result with all fields', () {
      final result = EventResult(
        afterEvent: 0,
        recomputeStructure: ['R', 'A'],
        recomputeLayout: ['R', 'A', 'B'],
        paintOrder: ['R', 'A', 'B'],
      );

      expect(result.afterEvent, 0);
      expect(result.recomputeStructure, ['R', 'A']);
      expect(result.recomputeLayout, ['R', 'A', 'B']);
      expect(result.paintOrder, ['R', 'A', 'B']);
    });

    test('should convert to JSON', () {
      final result = EventResult(
        afterEvent: 1,
        recomputeStructure: ['R'],
        recomputeLayout: ['R', 'A'],
        paintOrder: ['R', 'A', 'B'],
      );

      final json = result.toJson();

      expect(json['afterEvent'], 1);
      expect(json['recomputeStructure'], ['R']);
      expect(json['recomputeLayout'], ['R', 'A']);
      expect(json['paintOrder'], ['R', 'A', 'B']);
    });

    test('should create from JSON', () {
      final json = {
        'afterEvent': 2,
        'recomputeStructure': ['R', 'A'],
        'recomputeLayout': ['R'],
        'paintOrder': ['R', 'A', 'B', 'C'],
      };

      final result = EventResult.fromJson(json);

      expect(result.afterEvent, 2);
      expect(result.recomputeStructure, ['R', 'A']);
      expect(result.recomputeLayout, ['R']);
      expect(result.paintOrder, ['R', 'A', 'B', 'C']);
    });

    test('should support equality comparison', () {
      final result1 = EventResult(
        afterEvent: 0,
        recomputeStructure: ['R'],
        recomputeLayout: ['R', 'A'],
        paintOrder: ['R', 'A'],
      );

      final result2 = EventResult(
        afterEvent: 0,
        recomputeStructure: ['R'],
        recomputeLayout: ['R', 'A'],
        paintOrder: ['R', 'A'],
      );

      expect(result1, equals(result2));
    });

    test('should detect inequality', () {
      final result1 = EventResult(
        afterEvent: 0,
        recomputeStructure: ['R'],
        recomputeLayout: ['R'],
        paintOrder: ['R'],
      );

      final result2 = EventResult(
        afterEvent: 1,
        recomputeStructure: ['R'],
        recomputeLayout: ['R'],
        paintOrder: ['R'],
      );

      expect(result1, isNot(equals(result2)));
    });

    test('should have meaningful toString', () {
      final result = EventResult(
        afterEvent: 0,
        recomputeStructure: ['R', 'A'],
        recomputeLayout: ['R'],
        paintOrder: ['R', 'A', 'B'],
      );

      final str = result.toString();

      expect(str.contains('afterEvent: 0'), true);
      expect(str.contains('structure: 2'), true);
      expect(str.contains('layout: 1'), true);
      expect(str.contains('paint: 3'), true);
    });
  });

  group('Renderer', () {
    late NodeTree tree;
    late LayoutCalculator calculator;
    late Scheduler scheduler;
    late Renderer renderer;
    late Engine engine;

    setUp(() {
      tree = NodeTree();
      calculator = LayoutCalculator();
      scheduler = Scheduler(tree, calculator);
      renderer = Renderer(tree, scheduler);
      engine = Engine(tree);
    });

    test('should generate result after event processing', () {
      final root = RowNode(id: 'R');
      final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
      root.addChild(child);
      tree.initialize(root);

      // Process event
      final event = SetSizeEvent(
        targetId: 'A',
        newSize: Size(width: 100, height: 30),
      );
      engine.processEvent(event);

      // Generate result
      final result = renderer.generateResult(0);

      expect(result.afterEvent, 0);
      expect(result.recomputeLayout, contains('A'));
      expect(result.recomputeLayout, contains('R'));
      expect(result.paintOrder, ['R', 'A']);
    });

    test('should collect structure dirty nodes', () {
      final root = RowNode(id: 'R');
      tree.initialize(root);

      final event = AddChildEvent(
        targetId: 'R',
        child: BoxNode(id: 'A'),
      );
      engine.processEvent(event);

      final result = renderer.generateResult(0);

      expect(result.recomputeStructure, contains('R'));
      expect(result.recomputeStructure, contains('A'));
    });

    test('should generate paint order in pre-order DFS', () {
      final root = RowNode(id: 'R');
      final a = RowNode(id: 'A');
      final a1 = BoxNode(id: 'A1');
      final a2 = BoxNode(id: 'A2');
      final b = BoxNode(id: 'B');

      a.addChild(a1);
      a.addChild(a2);
      root.addChild(a);
      root.addChild(b);
      tree.initialize(root);

      final result = renderer.generateResult(0);

      expect(result.paintOrder, ['R', 'A', 'A1', 'A2', 'B']);
    });

    test('should handle multiple events', () {
      final root = RowNode(id: 'R');
      final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
      root.addChild(child);
      tree.initialize(root);

      // Event 1: setSize
      engine.processEvent(SetSizeEvent(
        targetId: 'A',
        newSize: Size(width: 100, height: 30),
      ));
      final result1 = renderer.generateResult(0);
      tree.clearAllDirtyFlags();

      // Event 2: addChild
      engine.processEvent(AddChildEvent(
        targetId: 'R',
        child: BoxNode(id: 'B'),
      ));
      final result2 = renderer.generateResult(1);

      expect(result1.afterEvent, 0);
      expect(result2.afterEvent, 1);
      expect(result1.paintOrder.length, 2);
      expect(result2.paintOrder.length, 3);
    });

    test('should generate results for multiple events', () {
      final root = RowNode(id: 'R');
      tree.initialize(root);

      // Process multiple events
      engine.processEvent(AddChildEvent(
        targetId: 'R',
        child: BoxNode(id: 'A'),
      ));
      final result1 = renderer.generateResult(0);
      tree.clearAllDirtyFlags();

      engine.processEvent(AddChildEvent(
        targetId: 'R',
        child: BoxNode(id: 'B'),
      ));
      final result2 = renderer.generateResult(1);

      final results = [result1, result2];

      expect(results.length, 2);
      expect(results[0].afterEvent, 0);
      expect(results[1].afterEvent, 1);
    });

    test('should convert results to JSON', () {
      final results = [
        EventResult(
          afterEvent: 0,
          recomputeStructure: ['R'],
          recomputeLayout: ['R', 'A'],
          paintOrder: ['R', 'A'],
        ),
        EventResult(
          afterEvent: 1,
          recomputeStructure: [],
          recomputeLayout: ['A'],
          paintOrder: ['R', 'A', 'B'],
        ),
      ];

      final json = renderer.resultsToJson(results);

      expect(json.length, 2);
      expect(json[0]['afterEvent'], 0);
      expect(json[1]['afterEvent'], 1);
    });

    test('should convert results from JSON', () {
      final json = [
        {
          'afterEvent': 0,
          'recomputeStructure': ['R'],
          'recomputeLayout': ['R'],
          'paintOrder': ['R', 'A'],
        },
        {
          'afterEvent': 1,
          'recomputeStructure': [],
          'recomputeLayout': ['A'],
          'paintOrder': ['R', 'A', 'B'],
        },
      ];

      final results = renderer.resultsFromJson(json);

      expect(results.length, 2);
      expect(results[0].afterEvent, 0);
      expect(results[1].afterEvent, 1);
    });

    test('should handle empty dirty lists', () {
      final root = BoxNode(id: 'R');
      tree.initialize(root);

      final result = renderer.generateResult(0);

      expect(result.recomputeStructure, isEmpty);
      expect(result.recomputeLayout, isEmpty);
      expect(result.paintOrder, ['R']);
    });

    test('should maintain layout order in result', () {
      final root = RowNode(id: 'R');
      final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
      final child2 = BoxNode(id: 'B', size: Size(width: 30, height: 20));
      root.addChild(child1);
      root.addChild(child2);
      tree.initialize(root);

      // Mark child2 and root dirty (child first due to depth)
      engine.processEvent(SetSizeEvent(
        targetId: 'B',
        newSize: Size(width: 60, height: 20),
      ));

      final result = renderer.generateResult(0);

      // Layout order should be bottom-up
      final layoutIds = result.recomputeLayout;
      final bIndex = layoutIds.indexOf('B');
      final rIndex = layoutIds.indexOf('R');
      final aIndex = layoutIds.indexOf('A');

      // B and A should come before R
      expect(bIndex, lessThan(rIndex));
      expect(aIndex, lessThan(rIndex));
    });
  });
}

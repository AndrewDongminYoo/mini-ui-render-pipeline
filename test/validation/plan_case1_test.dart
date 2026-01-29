// 🎯 Dart imports:
import 'dart:convert';

// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/render_pipeline.dart';

/// Test case from PLAN.md Example Case 1
void main() {
  group('PLAN.md Case 1 Validation', () {
    test('Event 0: No-op setSize should have empty recomputeLayout', () {
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {
              'type': 'Row',
              'children': ['A', 'B'],
            },
            'A': {
              'type': 'Box',
              'size': {'w': 50, 'h': 20},
            },
            'B': {
              'type': 'Box',
              'size': {'w': 30, 'h': 20},
            },
          },
        },
        'events': [
          {
            'type': 'setSize',
            'target': 'A',
            'newSize': {'w': 50, 'h': 20},
          },
        ],
      });

      final pipeline = RenderPipeline();
      final results = pipeline.process(inputJson);

      expect(results.length, 1);
      expect(results[0].afterEvent, 0);
      expect(results[0].recomputeStructure, isEmpty);
      expect(results[0].recomputeLayout, isEmpty);
      expect(results[0].paintOrder, ['R', 'A', 'B']);
    });

    test('Event 1: setSize should have recomputeLayout in correct order', () {
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {
              'type': 'Row',
              'children': ['A', 'B'],
            },
            'A': {
              'type': 'Box',
              'size': {'w': 50, 'h': 20},
            },
            'B': {
              'type': 'Box',
              'size': {'w': 30, 'h': 20},
            },
          },
        },
        'events': [
          {
            'type': 'setSize',
            'target': 'A',
            'newSize': {'w': 60, 'h': 20},
          },
        ],
      });

      final pipeline = RenderPipeline();
      final results = pipeline.process(inputJson);

      expect(results.length, 1);
      expect(results[0].afterEvent, 0);
      expect(results[0].recomputeStructure, isEmpty);

      // PLAN.md requires: ["A", "R", "B"] (direct → parent → sibling)
      print('Actual recomputeLayout: ${results[0].recomputeLayout}');
      print('Expected recomputeLayout: ["A", "R", "B"]');

      // Check if order matches PLAN.md
      expect(results[0].recomputeLayout, [
        'A',
        'R',
        'B',
      ], reason: 'PLAN.md requires order: direct node → parent → sibling');

      expect(results[0].paintOrder, ['R', 'A', 'B']);
    });
  });
}

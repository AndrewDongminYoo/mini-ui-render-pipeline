// 🎯 Dart imports:
import 'dart:convert';

// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/render_pipeline.dart';

void main() {
  group('RenderPipeline', () {
    late RenderPipeline pipeline;

    setUp(() {
      pipeline = RenderPipeline();
    });

    group('process', () {
      test('should process simple setSize event', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'size': {'w': 50, 'h': 20},
              },
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'R',
              'newSize': {'w': 100, 'h': 30},
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 1);
        expect(results[0].afterEvent, 0);
        expect(results[0].recomputeLayout, contains('R'));
        expect(results[0].paintOrder, ['R']);
      });

      test('should process addChild event', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Row'},
            },
          },
          'events': [
            {
              'type': 'addChild',
              'target': 'R',
              'child': {
                'id': 'A',
                'type': 'Box',
                'size': {'w': 50, 'h': 20},
              },
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 1);
        expect(results[0].recomputeStructure, contains('R'));
        expect(results[0].recomputeStructure, contains('A'));
        expect(results[0].paintOrder, ['R', 'A']);
      });

      test('should process multiple events sequentially', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Row',
                'children': ['A'],
              },
              'A': {
                'type': 'Box',
                'size': {'w': 50, 'h': 20},
              },
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'A',
              'newSize': {'w': 100, 'h': 30},
            },
            {
              'type': 'addChild',
              'target': 'R',
              'child': {
                'id': 'B',
                'type': 'Box',
                'size': {'w': 30, 'h': 20},
              },
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 2);

        // First event: setSize
        expect(results[0].afterEvent, 0);
        expect(results[0].recomputeLayout, contains('A'));
        expect(results[0].recomputeLayout, contains('R'));

        // Second event: addChild
        expect(results[1].afterEvent, 1);
        expect(results[1].recomputeStructure, contains('R'));
        expect(results[1].recomputeStructure, contains('B'));
        expect(results[1].paintOrder, ['R', 'A', 'B']);
      });

      test('should handle complex nested tree', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Column',
                'children': ['A'],
              },
              'A': {
                'type': 'Row',
                'children': ['A1', 'A2'],
              },
              'A1': {
                'type': 'Box',
                'size': {'w': 30, 'h': 20},
              },
              'A2': {
                'type': 'Box',
                'size': {'w': 20, 'h': 20},
              },
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'A1',
              'newSize': {'w': 60, 'h': 20},
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 1);

        // Size change should propagate to parent and siblings
        expect(results[0].recomputeLayout, contains('A1'));
        expect(results[0].recomputeLayout, contains('A2'));
        expect(results[0].recomputeLayout, contains('A'));
        expect(results[0].recomputeLayout, contains('R'));

        // Paint order should be pre-order DFS
        expect(results[0].paintOrder, ['R', 'A', 'A1', 'A2']);
      });

      test('should clear dirty flags between events', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'size': {'w': 50, 'h': 20},
              },
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'R',
              'newSize': {'w': 100, 'h': 30},
            },
            {
              'type': 'setPosition',
              'target': 'R',
              'newPosition': {'x': 10, 'y': 20},
            },
          ],
        });

        final results = pipeline.process(inputJson);

        // First event should mark R dirty
        expect(results[0].recomputeLayout, contains('R'));

        // Second event should only mark R dirty (not cumulative)
        expect(results[1].recomputeLayout, ['R']);
      });

      test('should handle removeChild event', () {
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
              'type': 'removeChild',
              'target': 'R',
              'childId': 'A',
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 1);
        expect(results[0].recomputeStructure, contains('R'));
        // Removed child is not in recomputeStructure (no longer in tree)
        expect(results[0].recomputeStructure, isNot(contains('A')));
        expect(results[0].paintOrder, ['R', 'B']);
      });

      test('should handle moveChild event', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Row',
                'children': ['A', 'B', 'C'],
              },
              'A': {'type': 'Box'},
              'B': {'type': 'Box'},
              'C': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'moveChild',
              'target': 'R',
              'fromIndex': 0,
              'toIndex': 2,
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 1);
        expect(results[0].recomputeStructure, contains('R'));
        expect(results[0].paintOrder, ['R', 'B', 'C', 'A']);
      });

      test('should handle setState event', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'state': {'color': 'red'},
              },
            },
          },
          'events': [
            {
              'type': 'setState',
              'target': 'R',
              'newState': {'color': 'blue'},
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 1);
        expect(results[0].recomputeLayout, contains('R'));
      });

      test('should handle empty events list', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Box'},
            },
          },
          'events': [],
        });

        final results = pipeline.process(inputJson);

        expect(results, isEmpty);
      });
    });

    group('processJson', () {
      test('should return valid JSON string', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'size': {'w': 50, 'h': 20},
              },
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'R',
              'newSize': {'w': 100, 'h': 30},
            },
          ],
        });

        final outputJson = pipeline.processJson(inputJson);

        // Should be valid JSON
        final decoded = jsonDecode(outputJson);
        expect(decoded, isA<List>());
        expect(decoded.length, 1);

        // Verify structure
        final result = decoded[0];
        expect(result['afterEvent'], 0);
        expect(result['recomputeLayout'], isA<List>());
        expect(result['paintOrder'], isA<List>());
      });

      test('should produce correct JSON format', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Row'},
            },
          },
          'events': [
            {
              'type': 'addChild',
              'target': 'R',
              'child': {
                'id': 'A',
                'type': 'Box',
              },
            },
          ],
        });

        final outputJson = pipeline.processJson(inputJson);
        final decoded = jsonDecode(outputJson) as List;
        final result = decoded[0];

        expect(result, containsPair('afterEvent', 0));
        expect(result, containsPair('recomputeStructure', isA<List>()));
        expect(result, containsPair('recomputeLayout', isA<List>()));
        expect(result, containsPair('paintOrder', isA<List>()));
      });
    });

    group('Integration scenarios', () {
      test('should handle realistic multi-step workflow', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'App',
            'nodes': {
              'App': {
                'type': 'Column',
                'children': ['Header', 'Body'],
              },
              'Header': {
                'type': 'Row',
                'children': ['Logo', 'Nav'],
              },
              'Logo': {
                'type': 'Box',
                'size': {'w': 100, 'h': 50},
              },
              'Nav': {
                'type': 'Row',
                'children': ['NavItem1', 'NavItem2'],
              },
              'NavItem1': {
                'type': 'Box',
                'size': {'w': 80, 'h': 30},
              },
              'NavItem2': {
                'type': 'Box',
                'size': {'w': 80, 'h': 30},
              },
              'Body': {
                'type': 'Box',
                'size': {'w': 300, 'h': 400},
              },
            },
          },
          'events': [
            // Resize logo
            {
              'type': 'setSize',
              'target': 'Logo',
              'newSize': {'w': 150, 'h': 50},
            },
            // Add new nav item
            {
              'type': 'addChild',
              'target': 'Nav',
              'child': {
                'id': 'NavItem3',
                'type': 'Box',
                'size': {'w': 80, 'h': 30},
              },
            },
            // Resize body
            {
              'type': 'setSize',
              'target': 'Body',
              'newSize': {'w': 350, 'h': 450},
            },
          ],
        });

        final results = pipeline.process(inputJson);

        expect(results.length, 3);

        // Event 0: Logo resize
        expect(results[0].recomputeLayout, contains('Logo'));
        expect(results[0].recomputeLayout, contains('Header'));

        // Event 1: Add nav item
        expect(results[1].recomputeStructure, contains('Nav'));
        expect(results[1].recomputeStructure, contains('NavItem3'));

        // Event 2: Body resize
        expect(results[2].recomputeLayout, contains('Body'));
        expect(results[2].recomputeLayout, contains('App'));
      });

      test('should maintain correct paint order through changes', () {
        final inputJson = jsonEncode({
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Stack',
                'children': ['Background', 'Content'],
              },
              'Background': {'type': 'Box'},
              'Content': {
                'type': 'Column',
                'children': ['Title', 'Body'],
              },
              'Title': {'type': 'Box'},
              'Body': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'addChild',
              'target': 'Content',
              'child': {
                'id': 'Footer',
                'type': 'Box',
              },
            },
          ],
        });

        final results = pipeline.process(inputJson);

        // Paint order should be maintained with new child
        expect(
          results[0].paintOrder,
          ['R', 'Background', 'Content', 'Title', 'Body', 'Footer'],
        );
      });
    });
  });
}

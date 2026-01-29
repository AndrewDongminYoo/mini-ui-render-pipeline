// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/node.dart';
import 'package:mini_ui/src/parser/json_parser.dart';

void main() {
  group('JsonParser', () {
    late JsonParser parser;

    setUp(() {
      parser = JsonParser();
    });

    group('parseTree', () {
      test('should parse simple tree with one node', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'size': {'w': 100, 'h': 50},
              },
            },
          },
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.id, 'R');
        expect(input.root, isA<BoxNode>());
        expect(input.root.size, Size(width: 100, height: 50));
      });

      test('should parse tree with parent-child relationships', () {
        final json = {
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
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.id, 'R');
        expect(input.root.children.length, 2);
        expect(input.root.children[0].id, 'A');
        expect(input.root.children[1].id, 'B');
      });

      test('should parse nested tree structure', () {
        final json = {
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
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.id, 'R');
        expect(input.root.children.length, 1);
        expect(input.root.children[0].id, 'A');
        expect(input.root.children[0].children.length, 2);
      });

      test('should parse all node types', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Row',
                'children': ['A', 'B', 'C', 'D'],
              },
              'A': {'type': 'Box'},
              'B': {'type': 'Row'},
              'C': {'type': 'Column'},
              'D': {'type': 'Stack'},
            },
          },
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.children[0], isA<BoxNode>());
        expect(input.root.children[1], isA<RowNode>());
        expect(input.root.children[2], isA<ColumnNode>());
        expect(input.root.children[3], isA<StackNode>());
      });

      test('should parse node with position', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'position': {'x': 10, 'y': 20},
              },
            },
          },
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.position, Position(x: 10, y: 20));
      });

      test('should parse node with state', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'state': {'color': 'red', 'opacity': 0.5},
              },
            },
          },
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.state, {'color': 'red', 'opacity': 0.5});
      });

      test('should handle nodes with all properties', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Box',
                'size': {'w': 100, 'h': 50},
                'position': {'x': 10, 'y': 20},
                'state': {'color': 'blue'},
              },
            },
          },
          'events': [],
        };

        final input = parser.parseJson(json);

        expect(input.root.size, Size(width: 100, height: 50));
        expect(input.root.position, Position(x: 10, y: 20));
        expect(input.root.state, {'color': 'blue'});
      });

      test('should throw on unknown node type', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Unknown'},
            },
          },
          'events': [],
        };

        expect(() => parser.parseJson(json), throwsArgumentError);
      });
    });

    group('parseEvents', () {
      test('should parse setSize event', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'R',
              'newSize': {'w': 100, 'h': 50},
            },
          ],
        };

        final input = parser.parseJson(json);

        expect(input.events.length, 1);
        expect(input.events[0], isA<SetSizeEvent>());
        final event = input.events[0] as SetSizeEvent;
        expect(event.targetId, 'R');
        expect(event.newSize, Size(width: 100, height: 50));
      });

      test('should parse setPosition event', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'setPosition',
              'target': 'R',
              'newPosition': {'x': 10, 'y': 20},
            },
          ],
        };

        final input = parser.parseJson(json);

        expect(input.events[0], isA<SetPositionEvent>());
        final event = input.events[0] as SetPositionEvent;
        expect(event.targetId, 'R');
        expect(event.newPosition, Position(x: 10, y: 20));
      });

      test('should parse setState event', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'setState',
              'target': 'R',
              'newState': {'color': 'red'},
            },
          ],
        };

        final input = parser.parseJson(json);

        expect(input.events[0], isA<SetStateEvent>());
        final event = input.events[0] as SetStateEvent;
        expect(event.targetId, 'R');
        expect(event.newState, {'color': 'red'});
      });

      test('should parse addChild event', () {
        final json = {
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
        };

        final input = parser.parseJson(json);

        expect(input.events[0], isA<AddChildEvent>());
        final event = input.events[0] as AddChildEvent;
        expect(event.targetId, 'R');
        expect(event.child.id, 'A');
        expect(event.child.size, Size(width: 50, height: 20));
      });

      test('should parse removeChild event', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Row',
                'children': ['A'],
              },
              'A': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'removeChild',
              'target': 'R',
              'childId': 'A',
            },
          ],
        };

        final input = parser.parseJson(json);

        expect(input.events[0], isA<RemoveChildEvent>());
        final event = input.events[0] as RemoveChildEvent;
        expect(event.targetId, 'R');
        expect(event.childId, 'A');
      });

      test('should parse moveChild event', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {
                'type': 'Row',
                'children': ['A', 'B'],
              },
              'A': {'type': 'Box'},
              'B': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'moveChild',
              'target': 'R',
              'fromIndex': 0,
              'toIndex': 1,
            },
          ],
        };

        final input = parser.parseJson(json);

        expect(input.events[0], isA<MoveChildEvent>());
        final event = input.events[0] as MoveChildEvent;
        expect(event.targetId, 'R');
        expect(event.fromIndex, 0);
        expect(event.toIndex, 1);
      });

      test('should parse multiple events', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'setSize',
              'target': 'R',
              'newSize': {'w': 100, 'h': 50},
            },
            {
              'type': 'setPosition',
              'target': 'R',
              'newPosition': {'x': 10, 'y': 20},
            },
          ],
        };

        final input = parser.parseJson(json);

        expect(input.events.length, 2);
        expect(input.events[0], isA<SetSizeEvent>());
        expect(input.events[1], isA<SetPositionEvent>());
      });

      test('should throw on unknown event type', () {
        final json = {
          'tree': {
            'root': 'R',
            'nodes': {
              'R': {'type': 'Box'},
            },
          },
          'events': [
            {
              'type': 'unknownEvent',
              'target': 'R',
            },
          ],
        };

        expect(() => parser.parseJson(json), throwsArgumentError);
      });
    });

    group('serializeTree', () {
      test('should serialize simple tree', () {
        final root = BoxNode(
          id: 'R',
          size: Size(width: 100, height: 50),
        );

        final json = parser.serializeTree(root);

        expect(json['root'], 'R');
        expect(json['nodes']['R']['type'], 'Box');
        expect(json['nodes']['R']['size'], {'w': 100.0, 'h': 50.0});
      });

      test('should serialize tree with children', () {
        final root = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 30, height: 20));
        root.addChild(child1);
        root.addChild(child2);

        final json = parser.serializeTree(root);

        expect(json['nodes']['R']['children'], ['A', 'B']);
        expect(json['nodes']['A']['type'], 'Box');
        expect(json['nodes']['B']['type'], 'Box');
      });

      test('should serialize nested tree', () {
        final root = ColumnNode(id: 'R');
        final child = RowNode(id: 'A');
        final grandchild = BoxNode(id: 'A1');
        child.addChild(grandchild);
        root.addChild(child);

        final json = parser.serializeTree(root);

        expect(json['nodes']['R']['children'], ['A']);
        expect(json['nodes']['A']['children'], ['A1']);
        expect(json['nodes'].length, 3);
      });

      test('should serialize node with all properties', () {
        final root = BoxNode(
          id: 'R',
          size: Size(width: 100, height: 50),
          position: Position(x: 10, y: 20),
          state: {'color': 'red'},
        );

        final json = parser.serializeTree(root);
        final nodeData = json['nodes']['R'];

        expect(nodeData['size'], {'w': 100.0, 'h': 50.0});
        expect(nodeData['position'], {'x': 10.0, 'y': 20.0});
        expect(nodeData['state'], {'color': 'red'});
      });

      test('should omit null properties', () {
        final root = BoxNode(id: 'R');

        final json = parser.serializeTree(root);
        final nodeData = json['nodes']['R'];

        expect(nodeData.containsKey('size'), false);
        expect(nodeData.containsKey('position'), false);
        expect(nodeData.containsKey('state'), false);
        expect(nodeData.containsKey('children'), false);
      });
    });

    group('serializeEvents', () {
      test('should serialize setSize event', () {
        final events = [
          SetSizeEvent(
            targetId: 'R',
            newSize: Size(width: 100, height: 50),
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json[0]['type'], 'setSize');
        expect(json[0]['target'], 'R');
        expect(json[0]['newSize'], {'w': 100.0, 'h': 50.0});
      });

      test('should serialize setPosition event', () {
        final events = [
          SetPositionEvent(
            targetId: 'R',
            newPosition: Position(x: 10, y: 20),
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json[0]['type'], 'setPosition');
        expect(json[0]['target'], 'R');
        expect(json[0]['newPosition'], {'x': 10.0, 'y': 20.0});
      });

      test('should serialize setState event', () {
        final events = [
          SetStateEvent(
            targetId: 'R',
            newState: {'color': 'red'},
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json[0]['type'], 'setState');
        expect(json[0]['target'], 'R');
        expect(json[0]['newState'], {'color': 'red'});
      });

      test('should serialize addChild event', () {
        final events = [
          AddChildEvent(
            targetId: 'R',
            child: BoxNode(id: 'A', size: Size(width: 50, height: 20)),
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json[0]['type'], 'addChild');
        expect(json[0]['target'], 'R');
        expect(json[0]['child']['id'], 'A');
        expect(json[0]['child']['type'], 'Box');
      });

      test('should serialize removeChild event', () {
        final events = [
          RemoveChildEvent(
            targetId: 'R',
            childId: 'A',
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json[0]['type'], 'removeChild');
        expect(json[0]['target'], 'R');
        expect(json[0]['childId'], 'A');
      });

      test('should serialize moveChild event', () {
        final events = [
          MoveChildEvent(
            targetId: 'R',
            fromIndex: 0,
            toIndex: 1,
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json[0]['type'], 'moveChild');
        expect(json[0]['target'], 'R');
        expect(json[0]['fromIndex'], 0);
        expect(json[0]['toIndex'], 1);
      });

      test('should serialize multiple events', () {
        final events = [
          SetSizeEvent(
            targetId: 'R',
            newSize: Size(width: 100, height: 50),
          ),
          SetPositionEvent(
            targetId: 'R',
            newPosition: Position(x: 10, y: 20),
          ),
        ];

        final json = parser.serializeEvents(events);

        expect(json.length, 2);
        expect(json[0]['type'], 'setSize');
        expect(json[1]['type'], 'setPosition');
      });
    });

    group('serializeInput', () {
      test('should serialize complete input', () {
        final root = RowNode(id: 'R');
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        root.addChild(child);

        final events = [
          SetSizeEvent(
            targetId: 'A',
            newSize: Size(width: 100, height: 30),
          ),
        ];

        final input = ParsedInput(root: root, events: events);
        final json = parser.serializeInput(input);

        expect(json['tree']['root'], 'R');
        expect(json['tree']['nodes'].length, 2);
        expect(json['events'].length, 1);
        expect(json['events'][0]['type'], 'setSize');
      });
    });

    group('Round-trip parsing', () {
      test('should parse and serialize to same structure', () {
        final originalJson = {
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
              'newSize': {'w': 100, 'h': 30},
            },
          ],
        };

        final input = parser.parseJson(originalJson);
        final serialized = parser.serializeInput(input);

        final originalTree = originalJson['tree'] as Map<String, dynamic>;
        final originalNodes = originalTree['nodes'] as Map<String, dynamic>;
        final originalEvents = originalJson['events'] as List<dynamic>;

        expect(serialized['tree']['root'], originalTree['root']);
        expect(
          (serialized['tree']['nodes'] as Map).length,
          originalNodes.length,
        );
        expect(
          (serialized['events'] as List).length,
          originalEvents.length,
        );
      });
    });

    group('ParsedInput', () {
      test('should have meaningful toString', () {
        final root = BoxNode(id: 'R');
        final events = [
          SetSizeEvent(
            targetId: 'R',
            newSize: Size(width: 100, height: 50),
          ),
          SetPositionEvent(
            targetId: 'R',
            newPosition: Position(x: 10, y: 20),
          ),
        ];

        final input = ParsedInput(root: root, events: events);
        final str = input.toString();

        expect(str.contains('root: R'), true);
        expect(str.contains('events: 2'), true);
      });
    });
  });
}

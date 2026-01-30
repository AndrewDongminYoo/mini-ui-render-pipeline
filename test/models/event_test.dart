// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/node.dart';

void main() {
  group('SetSizeEvent', () {
    test('should create event with target and size', () {
      final event = SetSizeEvent(
        targetId: 'A',
        newSize: Size(width: 100, height: 50),
      );

      expect(event.type, EventType.setSize);
      expect(event.targetId, 'A');
      expect(event.newSize.width, 100);
      expect(event.newSize.height, 50);
    });

    test('should have meaningful toString', () {
      final event = SetSizeEvent(
        targetId: 'A',
        newSize: Size(width: 100, height: 50),
      );

      final str = event.toString();
      expect(str.contains('SetSizeEvent'), true);
      expect(str.contains('A'), true);
    });
  });

  group('SetPositionEvent', () {
    test('should create event with target and position', () {
      final event = SetPositionEvent(
        targetId: 'B',
        newPosition: Position(x: 10, y: 20),
      );

      expect(event.type, EventType.setPosition);
      expect(event.targetId, 'B');
      expect(event.newPosition.x, 10);
      expect(event.newPosition.y, 20);
    });

    test('should have meaningful toString', () {
      final event = SetPositionEvent(
        targetId: 'B',
        newPosition: Position(x: 10, y: 20),
      );

      final str = event.toString();
      expect(str.contains('SetPositionEvent'), true);
      expect(str.contains('B'), true);
    });
  });

  group('SetStateEvent', () {
    test('should create event with target and state', () {
      final state = {'color': 'red', 'opacity': 0.8};
      final event = SetStateEvent(
        targetId: 'C',
        newState: state,
      );

      expect(event.type, EventType.setState);
      expect(event.targetId, 'C');
      expect(event.newState['color'], 'red');
      expect(event.newState['opacity'], 0.8);
    });

    test('should have meaningful toString', () {
      final event = SetStateEvent(
        targetId: 'C',
        newState: {'color': 'red'},
      );

      final str = event.toString();
      expect(str.contains('SetStateEvent'), true);
      expect(str.contains('C'), true);
    });
  });

  group('AddChildEvent', () {
    test('should create event with target and child', () {
      final child = BoxNode(id: 'child1');
      final event = AddChildEvent(
        targetId: 'parent',
        child: child,
      );

      expect(event.type, EventType.addChild);
      expect(event.targetId, 'parent');
      expect(event.child.id, 'child1');
      expect(event.index, null);
    });

    test('should support optional index', () {
      final child = BoxNode(id: 'child1');
      final event = AddChildEvent(
        targetId: 'parent',
        child: child,
        index: 2,
      );

      expect(event.index, 2);
    });

    test('should have meaningful toString', () {
      final child = BoxNode(id: 'child1');
      final event = AddChildEvent(
        targetId: 'parent',
        child: child,
        index: 1,
      );

      final str = event.toString();
      expect(str.contains('AddChildEvent'), true);
      expect(str.contains('parent'), true);
      expect(str.contains('child1'), true);
    });
  });

  group('RemoveChildEvent', () {
    test('should create event with target and child ID', () {
      final event = RemoveChildEvent(
        targetId: 'parent',
        childId: 'child1',
      );

      expect(event.type, EventType.removeChild);
      expect(event.targetId, 'parent');
      expect(event.childId, 'child1');
    });

    test('should have meaningful toString', () {
      final event = RemoveChildEvent(
        targetId: 'parent',
        childId: 'child1',
      );

      final str = event.toString();
      expect(str.contains('RemoveChildEvent'), true);
      expect(str.contains('parent'), true);
      expect(str.contains('child1'), true);
    });
  });

  group('MoveChildEvent', () {
    test('should create event with target and indices', () {
      final event = MoveChildEvent(
        targetId: 'parent',
        fromIndex: 0,
        toIndex: 2,
      );

      expect(event.type, EventType.moveChild);
      expect(event.targetId, 'parent');
      expect(event.fromIndex, 0);
      expect(event.toIndex, 2);
    });

    test('should have meaningful toString', () {
      final event = MoveChildEvent(
        targetId: 'parent',
        fromIndex: 1,
        toIndex: 3,
      );

      final str = event.toString();
      expect(str.contains('MoveChildEvent'), true);
      expect(str.contains('parent'), true);
      expect(str.contains('1'), true);
      expect(str.contains('3'), true);
    });
  });

  group('createEvent factory', () {
    test('should create SetSizeEvent from JSON', () {
      final json = {
        'type': 'setSize',
        'target': 'A',
        'newSize': {'w': 100, 'h': 50},
      };

      final event = createEvent(json);

      expect(event, isA<SetSizeEvent>());
      expect(event.targetId, 'A');
      final sizeEvent = event as SetSizeEvent;
      expect(sizeEvent.newSize.width, 100);
      expect(sizeEvent.newSize.height, 50);
    });

    test('should create SetPositionEvent from JSON', () {
      final json = {
        'type': 'setPosition',
        'target': 'B',
        'newPosition': {'x': 10, 'y': 20},
      };

      final event = createEvent(json);

      expect(event, isA<SetPositionEvent>());
      expect(event.targetId, 'B');
      final posEvent = event as SetPositionEvent;
      expect(posEvent.newPosition.x, 10);
      expect(posEvent.newPosition.y, 20);
    });

    test('should create SetStateEvent from JSON', () {
      final json = {
        'type': 'setState',
        'target': 'C',
        'newState': {'color': 'blue'},
      };

      final event = createEvent(json);

      expect(event, isA<SetStateEvent>());
      expect(event.targetId, 'C');
      final stateEvent = event as SetStateEvent;
      expect(stateEvent.newState['color'], 'blue');
    });

    test('should create RemoveChildEvent from JSON', () {
      final json = {
        'type': 'removeChild',
        'target': 'parent',
        'childId': 'child1',
      };

      final event = createEvent(json);

      expect(event, isA<RemoveChildEvent>());
      expect(event.targetId, 'parent');
      final removeEvent = event as RemoveChildEvent;
      expect(removeEvent.childId, 'child1');
    });

    test('should create MoveChildEvent from JSON', () {
      final json = {
        'type': 'moveChild',
        'target': 'parent',
        'fromIndex': 0,
        'toIndex': 2,
      };

      final event = createEvent(json);

      expect(event, isA<MoveChildEvent>());
      expect(event.targetId, 'parent');
      final moveEvent = event as MoveChildEvent;
      expect(moveEvent.fromIndex, 0);
      expect(moveEvent.toIndex, 2);
    });

    test('should be case-insensitive', () {
      final json = {
        'type': 'SETSIZE',
        'target': 'A',
        'newSize': {'w': 50, 'h': 25},
      };

      final event = createEvent(json);
      expect(event, isA<SetSizeEvent>());
    });

    test('should create AddChildEvent from JSON', () {
      final json = {
        'type': 'addChild',
        'target': 'parent',
        'child': {
          'id': 'child1',
          'type': 'Box',
          'size': {'w': 10, 'h': 20},
        },
      };

      final event = createEvent(json) as AddChildEvent;
      expect(event.targetId, 'parent');
      expect(event.child.id, 'child1');
    });

    test('should throw for unknown event type', () {
      final json = {
        'type': 'unknown',
        'target': 'A',
      };

      expect(
        () => createEvent(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle numeric size values', () {
      final json = {
        'type': 'setSize',
        'target': 'A',
        'newSize': {'w': 100.5, 'h': 50},
      };

      final event = createEvent(json) as SetSizeEvent;
      expect(event.newSize.width, 100.5);
      expect(event.newSize.height, 50);
    });
  });

  group('eventToJson', () {
    test('should convert SetSizeEvent to JSON', () {
      final event = SetSizeEvent(
        targetId: 'A',
        newSize: Size(width: 100, height: 50),
      );

      final json = eventToJson(event);

      expect(json['type'], 'setSize');
      expect(json['target'], 'A');
      expect(json['newSize']['w'], 100);
      expect(json['newSize']['h'], 50);
    });

    test('should convert SetPositionEvent to JSON', () {
      final event = SetPositionEvent(
        targetId: 'B',
        newPosition: Position(x: 10, y: 20),
      );

      final json = eventToJson(event);

      expect(json['type'], 'setPosition');
      expect(json['target'], 'B');
      expect(json['newPosition']['x'], 10);
      expect(json['newPosition']['y'], 20);
    });

    test('should convert SetStateEvent to JSON', () {
      final event = SetStateEvent(
        targetId: 'C',
        newState: {'color': 'red'},
      );

      final json = eventToJson(event);

      expect(json['type'], 'setState');
      expect(json['target'], 'C');
      expect(json['newState']['color'], 'red');
    });

    test('should convert RemoveChildEvent to JSON', () {
      final event = RemoveChildEvent(
        targetId: 'parent',
        childId: 'child1',
      );

      final json = eventToJson(event);

      expect(json['type'], 'removeChild');
      expect(json['target'], 'parent');
      expect(json['childId'], 'child1');
    });

    test('should convert MoveChildEvent to JSON', () {
      final event = MoveChildEvent(
        targetId: 'parent',
        fromIndex: 1,
        toIndex: 3,
      );

      final json = eventToJson(event);

      expect(json['type'], 'moveChild');
      expect(json['target'], 'parent');
      expect(json['fromIndex'], 1);
      expect(json['toIndex'], 3);
    });

    test('should convert AddChildEvent with index to JSON', () {
      final child = BoxNode(id: 'child1');
      final event = AddChildEvent(
        targetId: 'parent',
        child: child,
        index: 2,
      );

      final json = eventToJson(event);

      expect(json['type'], 'addChild');
      expect(json['target'], 'parent');
      expect(json['child']['id'], 'child1');
      expect(json['index'], 2);
    });

    test('should convert AddChildEvent without index to JSON', () {
      final child = BoxNode(id: 'child1');
      final event = AddChildEvent(
        targetId: 'parent',
        child: child,
      );

      final json = eventToJson(event);

      expect(json['type'], 'addChild');
      expect(json['target'], 'parent');
      expect(json['child']['id'], 'child1');
      expect(json.containsKey('index'), false);
    });
  });

  group('Event round-trip serialization', () {
    test('should round-trip SetSizeEvent', () {
      final original = SetSizeEvent(
        targetId: 'A',
        newSize: Size(width: 100, height: 50),
      );

      final json = eventToJson(original);
      final recovered = createEvent(json) as SetSizeEvent;

      expect(recovered.targetId, original.targetId);
      expect(recovered.newSize, original.newSize);
    });

    test('should round-trip SetPositionEvent', () {
      final original = SetPositionEvent(
        targetId: 'B',
        newPosition: Position(x: 10, y: 20),
      );

      final json = eventToJson(original);
      final recovered = createEvent(json) as SetPositionEvent;

      expect(recovered.targetId, original.targetId);
      expect(recovered.newPosition, original.newPosition);
    });

    test('should round-trip SetStateEvent', () {
      final original = SetStateEvent(
        targetId: 'C',
        newState: {'color': 'red', 'opacity': 0.5},
      );

      final json = eventToJson(original);
      final recovered = createEvent(json) as SetStateEvent;

      expect(recovered.targetId, original.targetId);
      expect(recovered.newState, original.newState);
    });

    test('should round-trip RemoveChildEvent', () {
      final original = RemoveChildEvent(
        targetId: 'parent',
        childId: 'child1',
      );

      final json = eventToJson(original);
      final recovered = createEvent(json) as RemoveChildEvent;

      expect(recovered.targetId, original.targetId);
      expect(recovered.childId, original.childId);
    });

    test('should round-trip MoveChildEvent', () {
      final original = MoveChildEvent(
        targetId: 'parent',
        fromIndex: 1,
        toIndex: 3,
      );

      final json = eventToJson(original);
      final recovered = createEvent(json) as MoveChildEvent;

      expect(recovered.targetId, original.targetId);
      expect(recovered.fromIndex, original.fromIndex);
      expect(recovered.toIndex, original.toIndex);
    });
  });
}

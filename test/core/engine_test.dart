// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/core/engine.dart';
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/node.dart';

void main() {
  group('Engine', () {
    late NodeTree tree;
    late Engine engine;

    setUp(() {
      tree = NodeTree();
      engine = Engine(tree);
    });

    group('SetSizeEvent', () {
      test('should update node size and mark dirty', () {
        final node = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        tree.initialize(node);

        final event = SetSizeEvent(
          targetId: 'A',
          newSize: Size(width: 100, height: 50),
        );

        final result = engine.processEvent(event);

        expect(result, true);
        expect(node.size, Size(width: 100, height: 50));
        expect(node.layoutDirty, true);
      });

      test('should mark parent and siblings dirty', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final b = BoxNode(id: 'B', size: Size(width: 30, height: 20));
        parent.addChild(a);
        parent.addChild(b);
        tree.initialize(parent);

        final event = SetSizeEvent(
          targetId: 'A',
          newSize: Size(width: 100, height: 20),
        );

        engine.processEvent(event);

        expect(a.layoutDirty, true);
        expect(parent.layoutDirty, true);
        expect(b.layoutDirty, true);
      });

      test('should detect no-op when size is same', () {
        final node = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        tree.initialize(node);

        final event = SetSizeEvent(
          targetId: 'A',
          newSize: Size(width: 50, height: 20),
        );

        final result = engine.processEvent(event);

        expect(result, false);
        expect(node.layoutDirty, false);
      });

      test('should handle node without parent', () {
        final node = BoxNode(id: 'A');
        tree.initialize(node);

        final event = SetSizeEvent(
          targetId: 'A',
          newSize: Size(width: 100, height: 50),
        );

        final result = engine.processEvent(event);

        expect(result, true);
        expect(node.layoutDirty, true);
      });
    });

    group('SetPositionEvent', () {
      test('should update node position and mark dirty', () {
        final node = BoxNode(id: 'A', position: Position(x: 0, y: 0));
        tree.initialize(node);

        final event = SetPositionEvent(
          targetId: 'A',
          newPosition: Position(x: 10, y: 20),
        );

        final result = engine.processEvent(event);

        expect(result, true);
        expect(node.position, Position(x: 10, y: 20));
        expect(node.layoutDirty, true);
      });

      test('should only mark self dirty, not parent or siblings', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A', position: Position(x: 0, y: 0));
        final b = BoxNode(id: 'B');
        parent.addChild(a);
        parent.addChild(b);
        tree.initialize(parent);

        final event = SetPositionEvent(
          targetId: 'A',
          newPosition: Position(x: 10, y: 20),
        );

        engine.processEvent(event);

        expect(a.layoutDirty, true);
        expect(parent.layoutDirty, false);
        expect(b.layoutDirty, false);
      });

      test('should detect no-op when position is same', () {
        final node = BoxNode(id: 'A', position: Position(x: 10, y: 20));
        tree.initialize(node);

        final event = SetPositionEvent(
          targetId: 'A',
          newPosition: Position(x: 10, y: 20),
        );

        final result = engine.processEvent(event);

        expect(result, false);
        expect(node.layoutDirty, false);
      });
    });

    group('SetStateEvent', () {
      test('should update node state and mark dirty', () {
        final node = BoxNode(id: 'A', state: {'color': 'red'});
        tree.initialize(node);

        final event = SetStateEvent(
          targetId: 'A',
          newState: {'color': 'blue', 'opacity': 0.8},
        );

        final result = engine.processEvent(event);

        expect(result, true);
        expect(node.state['color'], 'blue');
        expect(node.state['opacity'], 0.8);
        expect(node.layoutDirty, true);
      });

      test('should only mark self dirty', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A', state: {'color': 'red'});
        final b = BoxNode(id: 'B');
        parent.addChild(a);
        parent.addChild(b);
        tree.initialize(parent);

        final event = SetStateEvent(
          targetId: 'A',
          newState: {'color': 'blue'},
        );

        engine.processEvent(event);

        expect(a.layoutDirty, true);
        expect(parent.layoutDirty, false);
        expect(b.layoutDirty, false);
      });

      test('should detect no-op when state values are same', () {
        final node = BoxNode(id: 'A', state: {'color': 'red', 'opacity': 0.5});
        tree.initialize(node);

        final event = SetStateEvent(
          targetId: 'A',
          newState: {'color': 'red'},
        );

        final result = engine.processEvent(event);

        expect(result, false);
        expect(node.layoutDirty, false);
      });

      test('should detect change when adding new state key', () {
        final node = BoxNode(id: 'A', state: {'color': 'red'});
        tree.initialize(node);

        final event = SetStateEvent(
          targetId: 'A',
          newState: {'opacity': 0.8},
        );

        final result = engine.processEvent(event);

        expect(result, true);
        expect(node.state['opacity'], 0.8);
      });
    });

    group('AddChildEvent', () {
      test('should add child and mark structure dirty', () {
        final parent = RowNode(id: 'R');
        tree.initialize(parent);

        final child = BoxNode(id: 'A');
        final event = AddChildEvent(targetId: 'R', child: child);

        final result = engine.processEvent(event);

        expect(result, true);
        expect(parent.children.length, 1);
        expect(parent.children[0], child);
        expect(child.parent, parent);
        expect(parent.structureDirty, true);
        expect(child.structureDirty, true);
      });

      test('should mark parent, child, and siblings layout dirty', () {
        final parent = RowNode(id: 'R');
        final existing = BoxNode(id: 'B');
        parent.addChild(existing);
        tree.initialize(parent);

        final child = BoxNode(id: 'A');
        final event = AddChildEvent(targetId: 'R', child: child);

        engine.processEvent(event);

        expect(parent.layoutDirty, true);
        expect(child.layoutDirty, true);
        expect(existing.layoutDirty, true);
      });

      test('should support inserting at specific index', () {
        final parent = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A');
        final child2 = BoxNode(id: 'C');
        parent.addChild(child1);
        parent.addChild(child2);
        tree.initialize(parent);

        final newChild = BoxNode(id: 'B');
        final event = AddChildEvent(
          targetId: 'R',
          child: newChild,
          index: 1,
        );

        engine.processEvent(event);

        expect(parent.children.length, 3);
        expect(parent.children[0].id, 'A');
        expect(parent.children[1].id, 'B');
        expect(parent.children[2].id, 'C');
      });

      test('should add child node to tree map', () {
        final parent = RowNode(id: 'R');
        tree.initialize(parent);

        final child = BoxNode(id: 'A');
        final event = AddChildEvent(targetId: 'R', child: child);

        engine.processEvent(event);

        expect(tree.findNode('A'), child);
      });
    });

    group('RemoveChildEvent', () {
      test('should remove child and mark structure dirty', () {
        final parent = RowNode(id: 'R');
        final child = BoxNode(id: 'A');
        parent.addChild(child);
        tree.initialize(parent);

        final event = RemoveChildEvent(targetId: 'R', childId: 'A');

        final result = engine.processEvent(event);

        expect(result, true);
        expect(parent.children.length, 0);
        expect(child.parent, null);
        expect(parent.structureDirty, true);
        expect(child.structureDirty, true);
      });

      test('should mark parent and former siblings layout dirty', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        final b = BoxNode(id: 'B');
        final c = BoxNode(id: 'C');
        parent.addChild(a);
        parent.addChild(b);
        parent.addChild(c);
        tree.initialize(parent);

        final event = RemoveChildEvent(targetId: 'R', childId: 'B');

        engine.processEvent(event);

        expect(parent.layoutDirty, true);
        expect(a.layoutDirty, true);
        expect(c.layoutDirty, true);
      });

      test('should remove child node from tree map', () {
        final parent = RowNode(id: 'R');
        final child = BoxNode(id: 'A');
        parent.addChild(child);
        tree.initialize(parent);

        final event = RemoveChildEvent(targetId: 'R', childId: 'A');

        engine.processEvent(event);

        expect(tree.findNode('A'), null);
      });

      test('should throw when child not found', () {
        final parent = RowNode(id: 'R');
        tree.initialize(parent);

        final event = RemoveChildEvent(targetId: 'R', childId: 'nonexistent');

        expect(
          () => engine.processEvent(event),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('MoveChildEvent', () {
      test('should move child and mark structure dirty', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        final b = BoxNode(id: 'B');
        final c = BoxNode(id: 'C');
        parent.addChild(a);
        parent.addChild(b);
        parent.addChild(c);
        tree.initialize(parent);

        final event = MoveChildEvent(
          targetId: 'R',
          fromIndex: 0,
          toIndex: 2,
        );

        final result = engine.processEvent(event);

        expect(result, true);
        expect(parent.children[0], b);
        expect(parent.children[1], c);
        expect(parent.children[2], a);
        expect(parent.structureDirty, true);
      });

      test('should mark parent and all children layout dirty', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        final b = BoxNode(id: 'B');
        final c = BoxNode(id: 'C');
        parent.addChild(a);
        parent.addChild(b);
        parent.addChild(c);
        tree.initialize(parent);

        final event = MoveChildEvent(
          targetId: 'R',
          fromIndex: 0,
          toIndex: 2,
        );

        engine.processEvent(event);

        expect(parent.layoutDirty, true);
        expect(a.layoutDirty, true);
        expect(b.layoutDirty, true);
        expect(c.layoutDirty, true);
      });

      test('should detect no-op when fromIndex == toIndex', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        parent.addChild(a);
        tree.initialize(parent);

        final event = MoveChildEvent(
          targetId: 'R',
          fromIndex: 0,
          toIndex: 0,
        );

        final result = engine.processEvent(event);

        expect(result, false);
        expect(parent.structureDirty, false);
        expect(parent.layoutDirty, false);
      });

      test('should throw for invalid fromIndex', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        parent.addChild(a);
        tree.initialize(parent);

        final event = MoveChildEvent(
          targetId: 'R',
          fromIndex: 5,
          toIndex: 0,
        );

        expect(
          () => engine.processEvent(event),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw for invalid toIndex', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        parent.addChild(a);
        tree.initialize(parent);

        final event = MoveChildEvent(
          targetId: 'R',
          fromIndex: 0,
          toIndex: 5,
        );

        expect(
          () => engine.processEvent(event),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Error handling', () {
      test('should throw when target node not found', () {
        tree.initialize(BoxNode(id: 'A'));

        final event = SetSizeEvent(
          targetId: 'nonexistent',
          newSize: Size(width: 100, height: 50),
        );

        expect(
          () => engine.processEvent(event),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Dirty node collection', () {
      test('should get all dirty structure nodes', () {
        final parent = RowNode(id: 'R');
        final child = BoxNode(id: 'A');
        parent.addChild(child);
        tree.initialize(parent);

        final event = AddChildEvent(
          targetId: 'R',
          child: BoxNode(id: 'B'),
        );

        engine.processEvent(event);

        final dirtyStructure = engine.getDirtyStructureNodes();
        final ids = dirtyStructure.map((n) => n.id).toSet();

        expect(ids.contains('R'), true);
        expect(ids.contains('B'), true);
      });

      test('should get all dirty layout nodes', () {
        final parent = RowNode(id: 'R');
        final a = BoxNode(id: 'A');
        final b = BoxNode(id: 'B');
        parent.addChild(a);
        parent.addChild(b);
        tree.initialize(parent);

        final event = SetSizeEvent(
          targetId: 'A',
          newSize: Size(width: 100, height: 50),
        );

        engine.processEvent(event);

        final dirtyLayout = engine.getDirtyLayoutNodes();
        final ids = dirtyLayout.map((n) => n.id).toSet();

        expect(ids.contains('A'), true);
        expect(ids.contains('R'), true);
        expect(ids.contains('B'), true);
      });

      test('should clear all dirty flags', () {
        final parent = RowNode(id: 'R');
        final child = BoxNode(id: 'A');
        parent.addChild(child);
        tree.initialize(parent);

        final event = AddChildEvent(
          targetId: 'R',
          child: BoxNode(id: 'B'),
        );

        engine.processEvent(event);

        expect(parent.structureDirty, true);
        expect(parent.layoutDirty, true);

        engine.clearAllDirtyFlags();

        expect(parent.structureDirty, false);
        expect(parent.layoutDirty, false);
      });
    });
  });
}

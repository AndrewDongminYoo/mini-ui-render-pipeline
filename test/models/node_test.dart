// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/models/node.dart';

void main() {
  group('Size', () {
    test('should create size with width and height', () {
      final size = Size(width: 100, height: 50);
      expect(size.width, 100);
      expect(size.height, 50);
    });

    test('should support equality comparison', () {
      final size1 = Size(width: 100, height: 50);
      final size2 = Size(width: 100, height: 50);
      expect(size1, equals(size2));
    });

    test('should support copyWith', () {
      final size1 = Size(width: 100, height: 50);
      final size2 = size1.copyWith(width: 120);
      expect(size2.width, 120);
      expect(size2.height, 50);
    });
  });

  group('Position', () {
    test('should create position with x and y', () {
      final pos = Position(x: 10, y: 20);
      expect(pos.x, 10);
      expect(pos.y, 20);
    });

    test('should support equality comparison', () {
      final pos1 = Position(x: 10, y: 20);
      final pos2 = Position(x: 10, y: 20);
      expect(pos1, equals(pos2));
    });

    test('should support copyWith', () {
      final pos1 = Position(x: 10, y: 20);
      final pos2 = pos1.copyWith(x: 30);
      expect(pos2.x, 30);
      expect(pos2.y, 20);
    });
  });

  group('BoxNode', () {
    test('should create box node with ID', () {
      final box = BoxNode(id: 'A', size: Size(width: 50, height: 20));
      expect(box.id, 'A');
      expect(box.type, NodeType.box);
      expect(box.size?.width, 50);
      expect(box.isLeaf, true);
    });

    test('should mark dirty flags', () {
      final box = BoxNode(id: 'A');
      expect(box.layoutDirty, false);
      box.markLayoutDirty();
      expect(box.layoutDirty, true);
    });

    test('should clear dirty flags', () {
      final box = BoxNode(id: 'A', layoutDirty: true, structureDirty: true);
      expect(box.layoutDirty, true);
      expect(box.structureDirty, true);
      box.clearDirtyFlags();
      expect(box.layoutDirty, false);
      expect(box.structureDirty, false);
    });
  });

  group('RowNode', () {
    test('should create row node with children', () {
      final childA = BoxNode(id: 'A', size: Size(width: 50, height: 20));
      final childB = BoxNode(id: 'B', size: Size(width: 30, height: 20));
      final row = RowNode(id: 'R', children: [childA, childB]);

      expect(row.id, 'R');
      expect(row.type, NodeType.row);
      expect(row.children.length, 2);
      expect(row.isLeaf, false);
      expect(childA.parent, row);
      expect(childB.parent, row);
    });

    test('should add and remove children', () {
      final row = RowNode(id: 'R');
      final box = BoxNode(id: 'A');

      row.addChild(box);
      expect(row.children.length, 1);
      expect(box.parent, row);

      row.removeChild(box);
      expect(row.children.length, 0);
      expect(box.parent, null);
    });

    test('should find child by ID', () {
      final childA = BoxNode(id: 'A');
      final childB = BoxNode(id: 'B');
      final row = RowNode(id: 'R', children: [childA, childB]);

      final found = row.findChild('A');
      expect(found, childA);
    });

    test('should move child to new position', () {
      final childA = BoxNode(id: 'A');
      final childB = BoxNode(id: 'B');
      final childC = BoxNode(id: 'C');
      final row = RowNode(id: 'R', children: [childA, childB, childC]);

      row.moveChild(0, 2);
      expect(row.children[0], childB);
      expect(row.children[1], childC);
      expect(row.children[2], childA);
    });
  });

  group('ColumnNode', () {
    test('should create column node', () {
      final col = ColumnNode(id: 'C');
      expect(col.type, NodeType.column);
      expect(col.isContainer, true);
    });
  });

  group('StackNode', () {
    test('should create stack node', () {
      final stack = StackNode(id: 'S');
      expect(stack.type, NodeType.stack);
      expect(stack.isContainer, true);
    });
  });

  group('createNode factory', () {
    test('should create BoxNode from factory', () {
      final node = createNode(
        id: 'box1',
        type: 'box',
        size: Size(width: 100, height: 50),
      );
      expect(node, isA<BoxNode>());
      expect(node.id, 'box1');
      expect(node.type, NodeType.box);
    });

    test('should create RowNode from factory', () {
      final node = createNode(id: 'row1', type: 'row');
      expect(node, isA<RowNode>());
      expect(node.type, NodeType.row);
    });

    test('should create ColumnNode from factory', () {
      final node = createNode(id: 'col1', type: 'column');
      expect(node, isA<ColumnNode>());
      expect(node.type, NodeType.column);
    });

    test('should create StackNode from factory', () {
      final node = createNode(id: 'stack1', type: 'stack');
      expect(node, isA<StackNode>());
      expect(node.type, NodeType.stack);
    });

    test('should throw for unknown type', () {
      expect(
        () => createNode(id: 'unknown', type: 'unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should be case-insensitive', () {
      final node1 = createNode(id: 'box1', type: 'BOX');
      final node2 = createNode(id: 'ROW', type: 'row');
      expect(node1, isA<BoxNode>());
      expect(node2, isA<RowNode>());
    });
  });

  group('Node tree navigation', () {
    test('should find descendant recursively', () {
      final box1 = BoxNode(id: 'A1');
      final box2 = BoxNode(id: 'A2');
      final row = RowNode(id: 'A', children: [box1, box2]);
      final col = ColumnNode(id: 'R', children: [row]);

      final found = col.findDescendant('A2');
      expect(found, box2);
    });

    test('should return null for not found descendant', () {
      final row = RowNode(id: 'R');
      final found = row.findDescendant('nonexistent');
      expect(found, null);
    });

    test('should get child index', () {
      final box1 = BoxNode(id: 'A');
      final box2 = BoxNode(id: 'B');
      final row = RowNode(id: 'R', children: [box1, box2]);

      expect(row.getChildIndex(box1), 0);
      expect(row.getChildIndex(box2), 1);
    });

    test('should support custom state', () {
      final state = {'color': 'red', 'opacity': 0.8};
      final box = BoxNode(id: 'A', state: state);
      expect(box.state['color'], 'red');
      expect(box.state['opacity'], 0.8);
    });
  });
}

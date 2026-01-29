import 'package:test/test.dart';
import 'package:mini_ui/src/models/node.dart';
import 'package:mini_ui/src/layout/calculator.dart';

void main() {
  group('LayoutCalculator', () {
    late LayoutCalculator calculator;

    setUp(() {
      calculator = LayoutCalculator();
    });

    group('Box layout', () {
      test('should return existing size for box node', () {
        final box = BoxNode(id: 'A', size: Size(width: 100, height: 50));
        final size = calculator.calculateLayout(box);

        expect(size, Size(width: 100, height: 50));
      });

      test('should return null if box has no size', () {
        final box = BoxNode(id: 'A');
        final size = calculator.calculateLayout(box);

        expect(size, null);
      });
    });

    group('Row layout', () {
      test('should calculate width as sum of children widths', () {
        final row = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 30, height: 20));
        row.addChild(child1);
        row.addChild(child2);

        final size = calculator.calculateLayout(row);

        expect(size?.width, 80); // 50 + 30
        expect(size?.height, 20);
      });

      test('should calculate height as max of children heights', () {
        final row = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 30, height: 40));
        row.addChild(child1);
        row.addChild(child2);

        final size = calculator.calculateLayout(row);

        expect(size?.width, 80);
        expect(size?.height, 40); // max(20, 40)
      });

      test('should return 0x0 for row with no children', () {
        final row = RowNode(id: 'R');
        final size = calculator.calculateLayout(row);

        expect(size, Size(width: 0, height: 0));
      });

      test('should return null if any child has no size', () {
        final row = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B'); // No size
        row.addChild(child1);
        row.addChild(child2);

        final size = calculator.calculateLayout(row);

        expect(size, null);
      });
    });

    group('Column layout', () {
      test('should calculate height as sum of children heights', () {
        final col = ColumnNode(id: 'C');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 50, height: 30));
        col.addChild(child1);
        col.addChild(child2);

        final size = calculator.calculateLayout(col);

        expect(size?.width, 50);
        expect(size?.height, 50); // 20 + 30
      });

      test('should calculate width as max of children widths', () {
        final col = ColumnNode(id: 'C');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 70, height: 30));
        col.addChild(child1);
        col.addChild(child2);

        final size = calculator.calculateLayout(col);

        expect(size?.width, 70); // max(50, 70)
        expect(size?.height, 50);
      });

      test('should return 0x0 for column with no children', () {
        final col = ColumnNode(id: 'C');
        final size = calculator.calculateLayout(col);

        expect(size, Size(width: 0, height: 0));
      });

      test('should return null if any child has no size', () {
        final col = ColumnNode(id: 'C');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B'); // No size
        col.addChild(child1);
        col.addChild(child2);

        final size = calculator.calculateLayout(col);

        expect(size, null);
      });
    });

    group('Stack layout', () {
      test('should calculate width as max of children widths', () {
        final stack = StackNode(id: 'S');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 70, height: 30));
        stack.addChild(child1);
        stack.addChild(child2);

        final size = calculator.calculateLayout(stack);

        expect(size?.width, 70); // max(50, 70)
        expect(size?.height, 30); // max(20, 30)
      });

      test('should calculate height as max of children heights', () {
        final stack = StackNode(id: 'S');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 60));
        final child2 = BoxNode(id: 'B', size: Size(width: 70, height: 30));
        stack.addChild(child1);
        stack.addChild(child2);

        final size = calculator.calculateLayout(stack);

        expect(size?.width, 70);
        expect(size?.height, 60); // max(60, 30)
      });

      test('should return 0x0 for stack with no children', () {
        final stack = StackNode(id: 'S');
        final size = calculator.calculateLayout(stack);

        expect(size, Size(width: 0, height: 0));
      });

      test('should return null if any child has no size', () {
        final stack = StackNode(id: 'S');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B'); // No size
        stack.addChild(child1);
        stack.addChild(child2);

        final size = calculator.calculateLayout(stack);

        expect(size, null);
      });
    });

    group('Nested layouts', () {
      test('should calculate nested row in column', () {
        // Column containing a Row
        final col = ColumnNode(id: 'C');
        final row = RowNode(id: 'R');
        final box1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final box2 = BoxNode(id: 'B', size: Size(width: 30, height: 20));
        final box3 = BoxNode(id: 'C', size: Size(width: 100, height: 30));

        row.addChild(box1);
        row.addChild(box2);
        col.addChild(row);
        col.addChild(box3);

        // Calculate row first
        final rowSize = calculator.calculateLayout(row);
        row.size = rowSize;

        // Then calculate column
        final colSize = calculator.calculateLayout(col);

        expect(rowSize?.width, 80); // 50 + 30
        expect(rowSize?.height, 20);
        expect(colSize?.width, 100); // max(80, 100)
        expect(colSize?.height, 50); // 20 + 30
      });

      test('should calculate nested stack in row', () {
        // Row containing a Stack
        final row = RowNode(id: 'R');
        final stack = StackNode(id: 'S');
        final box1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final box2 = BoxNode(id: 'B', size: Size(width: 30, height: 40));
        final box3 = BoxNode(id: 'C', size: Size(width: 60, height: 30));

        stack.addChild(box1);
        stack.addChild(box2);
        row.addChild(stack);
        row.addChild(box3);

        // Calculate stack first
        final stackSize = calculator.calculateLayout(stack);
        stack.size = stackSize;

        // Then calculate row
        final rowSize = calculator.calculateLayout(row);

        expect(stackSize?.width, 50); // max(50, 30)
        expect(stackSize?.height, 40); // max(20, 40)
        expect(rowSize?.width, 110); // 50 + 60
        expect(rowSize?.height, 40); // max(40, 30)
      });
    });

    group('recalculateLayout', () {
      test('should update node size and return true when size changes', () {
        final row = RowNode(id: 'R', size: Size(width: 0, height: 0));
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        row.addChild(child);

        final updated = calculator.recalculateLayout(row);

        expect(updated, true);
        expect(row.size, Size(width: 50, height: 20));
      });

      test('should not update and return false when size is same', () {
        final row = RowNode(id: 'R', size: Size(width: 50, height: 20));
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        row.addChild(child);

        final updated = calculator.recalculateLayout(row);

        expect(updated, false);
      });

      test('should return false when size cannot be calculated', () {
        final row = RowNode(id: 'R', size: Size(width: 0, height: 0));
        final child = BoxNode(id: 'A'); // No size
        row.addChild(child);

        final updated = calculator.recalculateLayout(row);

        expect(updated, false);
        expect(row.size, Size(width: 0, height: 0)); // Unchanged
      });
    });

    group('recalculateLayouts', () {
      test('should recalculate multiple nodes in bottom-up order', () {
        // Create tree: R -> A, B where A is a row containing boxes
        final root = RowNode(id: 'R');
        final childRow = RowNode(id: 'A');
        final box1 = BoxNode(id: 'A1', size: Size(width: 30, height: 20));
        final box2 = BoxNode(id: 'A2', size: Size(width: 20, height: 20));
        final box3 = BoxNode(id: 'B', size: Size(width: 50, height: 30));

        childRow.addChild(box1);
        childRow.addChild(box2);
        root.addChild(childRow);
        root.addChild(box3);

        // Nodes in top-down order
        final nodes = [root, childRow];

        final updated = calculator.recalculateLayouts(nodes);

        // Both should be updated (childRow first, then root)
        expect(updated.length, 2);
        expect(childRow.size?.width, 50); // 30 + 20
        expect(childRow.size?.height, 20);
        expect(root.size?.width, 100); // 50 + 50
        expect(root.size?.height, 30); // max(20, 30)
      });

      test('should skip nodes that cannot be calculated', () {
        final row1 = RowNode(id: 'R1');
        final row2 = RowNode(id: 'R2');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B'); // No size

        row1.addChild(child1);
        row2.addChild(child2); // row2 cannot be calculated

        final nodes = [row1, row2];
        final updated = calculator.recalculateLayouts(nodes);

        expect(updated.length, 1);
        expect(updated[0].id, 'R1');
      });

      test('should return empty list when no nodes updated', () {
        final row = RowNode(id: 'R', size: Size(width: 50, height: 20));
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        row.addChild(child);

        final nodes = [row];
        final updated = calculator.recalculateLayouts(nodes);

        expect(updated, isEmpty);
      });
    });
  });
}

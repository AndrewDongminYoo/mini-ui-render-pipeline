// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/core/scheduler.dart';
import 'package:mini_ui/src/layout/calculator.dart';
import 'package:mini_ui/src/models/node.dart';

void main() {
  group('Scheduler', () {
    late NodeTree tree;
    late LayoutCalculator calculator;
    late Scheduler scheduler;

    setUp(() {
      tree = NodeTree();
      calculator = LayoutCalculator();
      scheduler = Scheduler(tree, calculator);
    });

    group('collectDirtyStructureNodes', () {
      test('should collect nodes marked as structure dirty', () {
        final root = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A');
        final child2 = BoxNode(id: 'B');
        root.addChild(child1);
        root.addChild(child2);
        tree.initialize(root);

        root.markStructureDirty();
        child1.markStructureDirty();

        final dirtyIds = scheduler.collectDirtyStructureNodes();

        expect(dirtyIds, contains('R'));
        expect(dirtyIds, contains('A'));
        expect(dirtyIds, isNot(contains('B')));
      });

      test('should return empty list when no structure dirty nodes', () {
        final root = BoxNode(id: 'R');
        tree.initialize(root);

        final dirtyIds = scheduler.collectDirtyStructureNodes();

        expect(dirtyIds, isEmpty);
      });
    });

    group('collectDirtyLayoutNodes', () {
      test('should collect nodes marked as layout dirty', () {
        final root = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A');
        final child2 = BoxNode(id: 'B');
        root.addChild(child1);
        root.addChild(child2);
        tree.initialize(root);

        root.markLayoutDirty();
        child2.markLayoutDirty();

        final dirtyIds = scheduler.collectDirtyLayoutNodes();

        expect(dirtyIds, contains('R'));
        expect(dirtyIds, contains('B'));
        expect(dirtyIds, isNot(contains('A')));
      });

      test('should return nodes in bottom-up order (children before parents)', () {
        final root = RowNode(id: 'R');
        final child = RowNode(id: 'A');
        final grandchild = BoxNode(id: 'A1');

        child.addChild(grandchild);
        root.addChild(child);
        tree.initialize(root);

        root.markLayoutDirty();
        child.markLayoutDirty();
        grandchild.markLayoutDirty();

        final dirtyIds = scheduler.collectDirtyLayoutNodes();

        // Grandchild (depth 2) should come before child (depth 1) before root (depth 0)
        final grandchildIndex = dirtyIds.indexOf('A1');
        final childIndex = dirtyIds.indexOf('A');
        final rootIndex = dirtyIds.indexOf('R');

        expect(grandchildIndex, lessThan(childIndex));
        expect(childIndex, lessThan(rootIndex));
      });

      test('should handle siblings at same depth', () {
        final root = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A');
        final child2 = BoxNode(id: 'B');
        root.addChild(child1);
        root.addChild(child2);
        tree.initialize(root);

        child1.markLayoutDirty();
        child2.markLayoutDirty();
        root.markLayoutDirty();

        final dirtyIds = scheduler.collectDirtyLayoutNodes();

        // Both children should come before root
        final child1Index = dirtyIds.indexOf('A');
        final child2Index = dirtyIds.indexOf('B');
        final rootIndex = dirtyIds.indexOf('R');

        expect(child1Index, lessThan(rootIndex));
        expect(child2Index, lessThan(rootIndex));
      });
    });

    group('recalculateDirtyLayouts', () {
      test('should recalculate layouts for dirty nodes', () {
        final root = RowNode(id: 'R');
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        root.addChild(child);
        tree.initialize(root);

        root.markLayoutDirty();

        final updated = scheduler.recalculateDirtyLayouts();

        expect(updated, contains('R'));
        expect(root.size, Size(width: 50, height: 20));
      });

      test('should process nodes in bottom-up order', () {
        final root = RowNode(id: 'R');
        final child = RowNode(id: 'A');
        final box1 = BoxNode(id: 'A1', size: Size(width: 30, height: 20));
        final box2 = BoxNode(id: 'A2', size: Size(width: 20, height: 20));

        child.addChild(box1);
        child.addChild(box2);
        root.addChild(child);
        tree.initialize(root);

        root.markLayoutDirty();
        child.markLayoutDirty();

        final updated = scheduler.recalculateDirtyLayouts();

        // Both should be updated
        expect(updated, contains('A'));
        expect(updated, contains('R'));

        // Check sizes
        expect(child.size?.width, 50); // 30 + 20
        expect(root.size?.width, 50);
      });

      test('should skip nodes that cannot be calculated', () {
        final root = RowNode(id: 'R');
        final child = BoxNode(id: 'A'); // No size
        root.addChild(child);
        tree.initialize(root);

        root.markLayoutDirty();

        final updated = scheduler.recalculateDirtyLayouts();

        expect(updated, isEmpty);
        expect(root.size, null);
      });

      test('should only update nodes with changed sizes', () {
        final root = RowNode(id: 'R', size: Size(width: 50, height: 20));
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        root.addChild(child);
        tree.initialize(root);

        root.markLayoutDirty();

        final updated = scheduler.recalculateDirtyLayouts();

        // Size didn't change, so not in updated list
        expect(updated, isEmpty);
      });
    });

    group('getComputationOrder', () {
      test('should return dirty nodes in bottom-up order', () {
        final root = RowNode(id: 'R');
        final child1 = RowNode(id: 'A');
        final child2 = BoxNode(id: 'B');
        final grandchild = BoxNode(id: 'A1');

        child1.addChild(grandchild);
        root.addChild(child1);
        root.addChild(child2);
        tree.initialize(root);

        root.markLayoutDirty();
        child1.markLayoutDirty();
        child2.markLayoutDirty();
        grandchild.markLayoutDirty();

        final nodes = scheduler.getComputationOrder();
        final ids = nodes.map((n) => n.id).toList();

        // Verify bottom-up order
        expect(ids.indexOf('A1'), lessThan(ids.indexOf('A')));
        expect(ids.indexOf('A'), lessThan(ids.indexOf('R')));
        expect(ids.indexOf('B'), lessThan(ids.indexOf('R')));
      });

      test('should return empty list when no dirty nodes', () {
        final root = BoxNode(id: 'R');
        tree.initialize(root);

        final nodes = scheduler.getComputationOrder();

        expect(nodes, isEmpty);
      });
    });

    group('processAllDirty', () {
      test('should process both structure and layout dirty nodes', () {
        final root = RowNode(id: 'R');
        final child = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        root.addChild(child);
        tree.initialize(root);

        root.markStructureDirty();
        root.markLayoutDirty();
        child.markStructureDirty();

        final summary = scheduler.processAllDirty();

        expect(summary.structureNodes, contains('R'));
        expect(summary.structureNodes, contains('A'));
        expect(summary.layoutNodes, contains('R'));
        expect(summary.updatedLayouts, contains('R'));
      });

      test('should return summary with counts', () {
        final root = RowNode(id: 'R');
        final child1 = BoxNode(id: 'A', size: Size(width: 50, height: 20));
        final child2 = BoxNode(id: 'B', size: Size(width: 30, height: 20));
        root.addChild(child1);
        root.addChild(child2);
        tree.initialize(root);

        root.markStructureDirty();
        root.markLayoutDirty();
        child1.markLayoutDirty();
        child2.markLayoutDirty();

        final summary = scheduler.processAllDirty();

        expect(summary.structureNodes.length, 1); // R
        expect(summary.layoutNodes.length, 3); // R, A, B
        expect(summary.updatedLayouts.length, 1); // R (children already have sizes)
      });

      test('should handle empty tree', () {
        tree.initialize(BoxNode(id: 'R'));

        final summary = scheduler.processAllDirty();

        expect(summary.structureNodes, isEmpty);
        expect(summary.layoutNodes, isEmpty);
        expect(summary.updatedLayouts, isEmpty);
      });
    });

    group('ProcessingSummary', () {
      test('should have meaningful toString', () {
        final summary = ProcessingSummary(
          structureNodes: ['R', 'A'],
          layoutNodes: ['R', 'A', 'B'],
          updatedLayouts: ['R'],
        );

        final str = summary.toString();

        expect(str.contains('structure: 2'), true);
        expect(str.contains('layout: 3'), true);
        expect(str.contains('updated: 1'), true);
      });
    });

    group('Complex scenarios', () {
      test('should handle deep nested tree', () {
        // Create a 4-level tree
        final root = ColumnNode(id: 'R');
        final level1 = RowNode(id: 'L1');
        final level2 = ColumnNode(id: 'L2');
        final level3 = BoxNode(id: 'L3', size: Size(width: 50, height: 20));

        level2.addChild(level3);
        level1.addChild(level2);
        root.addChild(level1);
        tree.initialize(root);

        root.markLayoutDirty();
        level1.markLayoutDirty();
        level2.markLayoutDirty();

        final updated = scheduler.recalculateDirtyLayouts();

        // All should be calculated
        expect(updated.length, 3);
        expect(level2.size?.width, 50);
        expect(level2.size?.height, 20);
      });

      test('should handle multiple branches', () {
        final root = RowNode(id: 'R');
        final branch1 = ColumnNode(id: 'B1');
        final branch2 = ColumnNode(id: 'B2');
        final box1 = BoxNode(id: 'A1', size: Size(width: 30, height: 20));
        final box2 = BoxNode(id: 'A2', size: Size(width: 40, height: 30));

        branch1.addChild(box1);
        branch2.addChild(box2);
        root.addChild(branch1);
        root.addChild(branch2);
        tree.initialize(root);

        root.markLayoutDirty();
        branch1.markLayoutDirty();
        branch2.markLayoutDirty();

        final updated = scheduler.recalculateDirtyLayouts();

        expect(updated.length, 3);
        expect(branch1.size, Size(width: 30, height: 20));
        expect(branch2.size, Size(width: 40, height: 30));
        expect(root.size, Size(width: 70, height: 30)); // 30+40, max(20,30)
      });
    });
  });
}

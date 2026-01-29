// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/models/node.dart';

void main() {
  group('NodeTree', () {
    late NodeTree tree;

    setUp(() {
      tree = NodeTree();
    });

    test('should initialize with root node', () {
      final root = BoxNode(id: 'root');
      tree.initialize(root);
      expect(tree.root, root);
      expect(tree.findNode('root'), root);
    });

    test('should be empty initially', () {
      expect(tree.root, null);
      expect(tree.getAllNodes(), isEmpty);
    });

    test('should find nodes by ID', () {
      final root = RowNode(id: 'R');
      final childA = BoxNode(id: 'A');
      final childB = BoxNode(id: 'B');
      root.addChild(childA);
      root.addChild(childB);

      tree.initialize(root);

      expect(tree.findNode('R'), root);
      expect(tree.findNode('A'), childA);
      expect(tree.findNode('B'), childB);
      expect(tree.findNode('nonexistent'), null);
    });

    test('should get all nodes in pre-order', () {
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

      final nodes = tree.getAllNodes();
      final nodeIds = nodes.map((n) => n.id).toList();

      expect(nodeIds, ['R', 'A', 'A1', 'A2', 'B']);
    });

    test('should get paint order as pre-order DFS', () {
      final root = ColumnNode(id: 'R');
      final a = RowNode(id: 'A');
      final a1 = BoxNode(id: 'A1');
      final a2 = BoxNode(id: 'A2');
      final b = BoxNode(id: 'B');

      a.addChild(a1);
      a.addChild(a2);
      root.addChild(a);
      root.addChild(b);

      tree.initialize(root);

      final paintOrder = tree.getPaintOrder();
      expect(paintOrder, ['R', 'A', 'A1', 'A2', 'B']);
    });

    test('should track dirty structure nodes', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      final b = BoxNode(id: 'B');

      root.addChild(a);
      root.addChild(b);
      tree.initialize(root);

      a.markStructureDirty();
      b.markLayoutDirty();

      final dirtyStructure = tree.getDirtyStructureNodes();
      expect(dirtyStructure.map((n) => n.id), ['A']);

      final dirtyLayout = tree.getDirtyLayoutNodes();
      expect(dirtyLayout.map((n) => n.id), ['B']);
    });

    test('should clear all dirty flags', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      root.addChild(a);
      tree.initialize(root);

      a.markStructureDirty();
      a.markLayoutDirty();
      root.markStructureDirty();

      tree.clearAllDirtyFlags();

      expect(root.structureDirty, false);
      expect(root.layoutDirty, false);
      expect(a.structureDirty, false);
      expect(a.layoutDirty, false);
    });

    test('should validate tree structure', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      root.addChild(a);
      tree.initialize(root);

      final errors = tree.validate();
      expect(errors, isEmpty);
    });

    test('should detect invalid tree (root with parent)', () {
      final parent = RowNode(id: 'parent');
      final root = BoxNode(id: 'root');
      parent.addChild(root);
      tree.initialize(root);

      final errors = tree.validate();
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Root node has a parent')), true);
    });

    test('should detect parent-child mismatch', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      final b = BoxNode(id: 'B');

      root.addChild(a);
      root.addChild(b);
      tree.initialize(root);

      // Manually break the consistency
      a.parent = b;

      final errors = tree.validate();
      expect(errors.any((e) => e.contains('Parent-child mismatch')), true);
    });

    test('should get siblings of a node', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      final b = BoxNode(id: 'B');
      final c = BoxNode(id: 'C');

      root.addChild(a);
      root.addChild(b);
      root.addChild(c);
      tree.initialize(root);

      final siblingsOfB = tree.getSiblings(b);
      final siblingIds = siblingsOfB.map((n) => n.id).toSet();

      expect(siblingIds, {'A', 'C'});
    });

    test('should get node depth', () {
      final root = RowNode(id: 'R');
      final a = RowNode(id: 'A');
      final a1 = BoxNode(id: 'A1');

      a.addChild(a1);
      root.addChild(a);
      tree.initialize(root);

      expect(tree.getNodeDepth(root), 0);
      expect(tree.getNodeDepth(a), 1);
      expect(tree.getNodeDepth(a1), 2);
    });

    test('should get ancestors of a node', () {
      final root = RowNode(id: 'R');
      final a = RowNode(id: 'A');
      final a1 = ColumnNode(id: 'A1');
      final a1a = BoxNode(id: 'A1A');

      a1.addChild(a1a);
      a.addChild(a1);
      root.addChild(a);
      tree.initialize(root);

      final ancestors = tree.getAncestors(a1a);
      final ancestorIds = ancestors.map((n) => n.id).toList();

      expect(ancestorIds, ['A1', 'A', 'R']);
    });

    test('should get descendants of a node', () {
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

      final descendants = tree.getDescendants(root);
      final descendantIds = descendants.map((n) => n.id).toSet();

      expect(descendantIds, {'A', 'A1', 'A2', 'B'});
    });

    test('should remove node and its subtree', () {
      final root = RowNode(id: 'R');
      final a = RowNode(id: 'A');
      final a1 = BoxNode(id: 'A1');
      final b = BoxNode(id: 'B');

      a.addChild(a1);
      root.addChild(a);
      root.addChild(b);
      tree.initialize(root);

      expect(tree.getAllNodes().length, 4);

      tree.removeNode('A');

      expect(tree.findNode('A'), null);
      expect(tree.findNode('A1'), null);
      expect(tree.findNode('B'), isNotNull);
      expect(tree.getAllNodes().length, 2);
    });

    test('should add new node to tree', () {
      final root = RowNode(id: 'R');
      tree.initialize(root);

      final newBox = BoxNode(id: 'NEW');
      tree.addNode(newBox);

      expect(tree.findNode('NEW'), newBox);
    });

    test('should throw when adding duplicate node ID', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      root.addChild(a);
      tree.initialize(root);

      final duplicate = BoxNode(id: 'A');
      expect(() => tree.addNode(duplicate), throwsA(isA<ArgumentError>()));
    });

    test('should debug print tree structure', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A', size: Size(width: 50, height: 20));
      root.addChild(a);
      tree.initialize(root);

      final debugOutput = tree.debugPrint();

      expect(debugOutput.contains('ROW(R)'), true);
      expect(debugOutput.contains('BOX(A)'), true);
      expect(debugOutput.contains('[50') && debugOutput.contains('20'), true);
    });

    test('should show dirty flags in debug output', () {
      final root = RowNode(id: 'R');
      final a = BoxNode(id: 'A');
      root.addChild(a);
      tree.initialize(root);

      a.markStructureDirty();
      root.markLayoutDirty();

      final debugOutput = tree.debugPrint();

      expect(debugOutput.contains('[DIRTY:S]'), true);
      expect(debugOutput.contains('[DIRTY:L]'), true);
    });
  });
}

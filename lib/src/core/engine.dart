// 🌎 Project imports:
import 'package:mini_ui/src/core/node_tree.dart';
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/node.dart';

/// Engine for processing events and managing dirty flags.
class Engine {
  /// The node tree being managed.
  final NodeTree tree;

  Engine(this.tree);

  /// Process an event and update dirty flags accordingly.
  /// Returns true if the event caused changes, false if it was a no-op.
  bool processEvent(Event event) {
    final target = tree.findNode(event.targetId);
    if (target == null) {
      throw ArgumentError('Node ${event.targetId} not found');
    }

    switch (event.type) {
      case EventType.setSize:
        return _processSetSize(target, event as SetSizeEvent);
      case EventType.setPosition:
        return _processSetPosition(target, event as SetPositionEvent);
      case EventType.setState:
        return _processSetState(target, event as SetStateEvent);
      case EventType.addChild:
        return _processAddChild(target, event as AddChildEvent);
      case EventType.removeChild:
        return _processRemoveChild(target, event as RemoveChildEvent);
      case EventType.moveChild:
        return _processMoveChild(target, event as MoveChildEvent);
    }
  }

  /// Process setSize event.
  /// No-op if size is already the same.
  /// Marks: self + parent + siblings as layout dirty.
  bool _processSetSize(Node target, SetSizeEvent event) {
    // No-op detection
    if (target.size == event.newSize) {
      return false;
    }

    // Update size
    target.size = event.newSize;

    // Mark dirty flags
    target.markLayoutDirty();

    // Mark parent dirty
    if (target.parent != null) {
      target.parent!.markLayoutDirty();

      // Mark siblings dirty
      for (final sibling in tree.getSiblings(target)) {
        sibling.markLayoutDirty();
      }
    }

    return true;
  }

  /// Process setPosition event.
  /// No-op if position is already the same.
  /// Marks: self as layout dirty.
  bool _processSetPosition(Node target, SetPositionEvent event) {
    // No-op detection
    if (target.position == event.newPosition) {
      return false;
    }

    // Update position
    target.position = event.newPosition;

    // Mark dirty flags
    target.markLayoutDirty();

    return true;
  }

  /// Process setState event.
  /// No-op if state values are already the same.
  /// Marks: self as layout dirty.
  bool _processSetState(Node target, SetStateEvent event) {
    // No-op detection: check if any state value actually changes
    bool hasChange = false;
    for (final entry in event.newState.entries) {
      if (target.state[entry.key] != entry.value) {
        hasChange = true;
        break;
      }
    }

    if (!hasChange) {
      return false;
    }

    // Update state
    for (final entry in event.newState.entries) {
      target.state[entry.key] = entry.value;
    }

    // Mark dirty flags
    target.markLayoutDirty();

    return true;
  }

  /// Process addChild event.
  /// Marks: parent + child as structure dirty.
  /// Marks: parent + child + siblings as layout dirty.
  bool _processAddChild(Node target, AddChildEvent event) {
    // Add child
    final child = event.child;

    if (event.index != null) {
      child.parent = target;
      target.children.insert(event.index!, child);
    } else {
      target.addChild(child);
    }

    // Add child to tree
    tree.addNode(child);

    // Mark structure dirty
    target.markStructureDirty();
    child.markStructureDirty();

    // Mark layout dirty
    target.markLayoutDirty();
    child.markLayoutDirty();

    // Mark siblings dirty
    for (final sibling in tree.getSiblings(child)) {
      sibling.markLayoutDirty();
    }

    return true;
  }

  /// Process removeChild event.
  /// Marks: parent + child as structure dirty.
  /// Marks: parent + siblings as layout dirty.
  bool _processRemoveChild(Node target, RemoveChildEvent event) {
    final child = target.findChild(event.childId);
    if (child == null) {
      throw ArgumentError('Child ${event.childId} not found in ${target.id}');
    }

    // Get siblings before removing
    final siblings = tree.getSiblings(child);

    // Remove child
    target.removeChild(child);

    // Remove child from tree
    tree.removeNode(child.id);

    // Mark structure dirty
    target.markStructureDirty();
    child.markStructureDirty();

    // Mark layout dirty
    target.markLayoutDirty();

    // Mark former siblings dirty
    for (final sibling in siblings) {
      sibling.markLayoutDirty();
    }

    return true;
  }

  /// Process moveChild event.
  /// No-op if fromIndex == toIndex.
  /// Marks: parent as structure dirty.
  /// Marks: parent + all children as layout dirty.
  bool _processMoveChild(Node target, MoveChildEvent event) {
    // No-op detection
    if (event.fromIndex == event.toIndex) {
      return false;
    }

    // Validate indices
    if (event.fromIndex < 0 ||
        event.fromIndex >= target.children.length ||
        event.toIndex < 0 ||
        event.toIndex >= target.children.length) {
      throw ArgumentError(
        'Invalid indices for moveChild: from=${event.fromIndex}, to=${event.toIndex}, children=${target.children.length}',
      );
    }

    // Move child
    target.moveChild(event.fromIndex, event.toIndex);

    // Mark structure dirty
    target.markStructureDirty();

    // Mark layout dirty (parent + all children)
    target.markLayoutDirty();
    for (final child in target.children) {
      child.markLayoutDirty();
    }

    return true;
  }

  /// Get all dirty structure nodes.
  List<Node> getDirtyStructureNodes() {
    return tree.getDirtyStructureNodes();
  }

  /// Get all dirty layout nodes.
  List<Node> getDirtyLayoutNodes() {
    return tree.getDirtyLayoutNodes();
  }

  /// Clear all dirty flags in the tree.
  void clearAllDirtyFlags() {
    tree.clearAllDirtyFlags();
  }
}

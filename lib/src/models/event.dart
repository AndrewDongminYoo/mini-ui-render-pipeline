import 'package:mini_ui/src/models/node.dart';

/// Enum for event types.
enum EventType {
  setSize,
  setPosition,
  setState,
  addChild,
  removeChild,
  moveChild,
}

/// Base class for all UI events.
abstract class Event {
  /// Type of this event.
  final EventType type;

  /// Target node ID for this event.
  final String targetId;

  Event({required this.type, required this.targetId});

  @override
  String toString() {
    return '${type.name}(target: $targetId)';
  }
}

/// Event to set the size of a node.
class SetSizeEvent extends Event {
  /// New size for the node.
  final Size newSize;

  SetSizeEvent({
    required super.targetId,
    required this.newSize,
  }) : super(type: EventType.setSize);

  @override
  String toString() {
    return 'SetSizeEvent(target: $targetId, size: $newSize)';
  }
}

/// Event to set the position of a node.
class SetPositionEvent extends Event {
  /// New position for the node.
  final Position newPosition;

  SetPositionEvent({
    required super.targetId,
    required this.newPosition,
  }) : super(type: EventType.setPosition);

  @override
  String toString() {
    return 'SetPositionEvent(target: $targetId, position: $newPosition)';
  }
}

/// Event to set custom state of a node.
class SetStateEvent extends Event {
  /// New state values to merge into the node's state.
  final Map<String, dynamic> newState;

  SetStateEvent({
    required super.targetId,
    required this.newState,
  }) : super(type: EventType.setState);

  @override
  String toString() {
    return 'SetStateEvent(target: $targetId, state: $newState)';
  }
}

/// Event to add a child to a node.
class AddChildEvent extends Event {
  /// Child node to add.
  final Node child;

  /// Optional index at which to insert the child.
  /// If null, appends to the end.
  final int? index;

  AddChildEvent({
    required super.targetId,
    required this.child,
    this.index,
  }) : super(type: EventType.addChild);

  @override
  String toString() {
    return 'AddChildEvent(target: $targetId, child: ${child.id}, index: $index)';
  }
}

/// Event to remove a child from a node.
class RemoveChildEvent extends Event {
  /// ID of the child to remove.
  final String childId;

  RemoveChildEvent({
    required super.targetId,
    required this.childId,
  }) : super(type: EventType.removeChild);

  @override
  String toString() {
    return 'RemoveChildEvent(target: $targetId, child: $childId)';
  }
}

/// Event to move a child within a node's children list.
class MoveChildEvent extends Event {
  /// Current index of the child.
  final int fromIndex;

  /// New index for the child.
  final int toIndex;

  MoveChildEvent({
    required super.targetId,
    required this.fromIndex,
    required this.toIndex,
  }) : super(type: EventType.moveChild);

  @override
  String toString() {
    return 'MoveChildEvent(target: $targetId, from: $fromIndex, to: $toIndex)';
  }
}

/// Factory function to create an event from a JSON-like map.
Event createEvent(Map<String, dynamic> json) {
  final type = json['type'] as String;
  final targetId = json['target'] as String;

  switch (type.toLowerCase()) {
    case 'setsize':
      final sizeMap = json['size'] as Map<String, dynamic>;
      return SetSizeEvent(
        targetId: targetId,
        newSize: Size(
          width: (sizeMap['w'] as num).toDouble(),
          height: (sizeMap['h'] as num).toDouble(),
        ),
      );

    case 'setposition':
      final posMap = json['position'] as Map<String, dynamic>;
      return SetPositionEvent(
        targetId: targetId,
        newPosition: Position(
          x: (posMap['x'] as num).toDouble(),
          y: (posMap['y'] as num).toDouble(),
        ),
      );

    case 'setstate':
      final state = json['state'] as Map<String, dynamic>;
      return SetStateEvent(
        targetId: targetId,
        newState: state,
      );

    case 'addchild':
      // Note: In practice, child would be constructed from JSON
      // For now, this is a simplified version
      throw UnimplementedError(
        'AddChildEvent creation from JSON requires node deserialization',
      );

    case 'removechild':
      final childId = json['childId'] as String;
      return RemoveChildEvent(
        targetId: targetId,
        childId: childId,
      );

    case 'movechild':
      final from = json['from'] as int;
      final to = json['to'] as int;
      return MoveChildEvent(
        targetId: targetId,
        fromIndex: from,
        toIndex: to,
      );

    default:
      throw ArgumentError('Unknown event type: $type');
  }
}

/// Convert an event to a JSON-serializable map.
Map<String, dynamic> eventToJson(Event event) {
  final base = <String, dynamic>{
    'type': event.type.name,
    'target': event.targetId,
  };

  if (event is SetSizeEvent) {
    base['size'] = {
      'w': event.newSize.width,
      'h': event.newSize.height,
    };
  } else if (event is SetPositionEvent) {
    base['position'] = {
      'x': event.newPosition.x,
      'y': event.newPosition.y,
    };
  } else if (event is SetStateEvent) {
    base['state'] = event.newState;
  } else if (event is AddChildEvent) {
    base['childId'] = event.child.id;
    if (event.index != null) {
      base['index'] = event.index;
    }
  } else if (event is RemoveChildEvent) {
    base['childId'] = event.childId;
  } else if (event is MoveChildEvent) {
    base['from'] = event.fromIndex;
    base['to'] = event.toIndex;
  }

  return base;
}

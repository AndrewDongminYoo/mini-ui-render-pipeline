// 🌎 Project imports:
import 'package:mini_ui/src/models/node.dart';
import 'package:mini_ui/src/utils/parsing_utils.dart';

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
      final sizeMap = _readMap(json, ['newSize', 'size'], 'setSize');
      return SetSizeEvent(
        targetId: targetId,
        newSize: parseSize(sizeMap),
      );

    case 'setposition':
      final posMap = _readMap(json, ['newPosition', 'position'], 'setPosition');
      return SetPositionEvent(
        targetId: targetId,
        newPosition: parsePosition(posMap),
      );

    case 'setstate':
      final state = _readMap(json, ['newState', 'state'], 'setState');
      return SetStateEvent(
        targetId: targetId,
        newState: state,
      );

    case 'addchild':
      final childJson = json['child'] as Map<String, dynamic>?;
      if (childJson == null) {
        throw FormatException('addChild requires a "child" object');
      }
      final index = json['index'] as int?;
      return AddChildEvent(
        targetId: targetId,
        child: _parseNode(childJson),
        index: index,
      );

    case 'removechild':
      final childId = json['childId'] as String;
      return RemoveChildEvent(
        targetId: targetId,
        childId: childId,
      );

    case 'movechild':
      final from = _readInt(json, ['fromIndex', 'from'], 'moveChild.fromIndex');
      final to = _readInt(json, ['toIndex', 'to'], 'moveChild.toIndex');
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
    base['newSize'] = {
      'w': event.newSize.width,
      'h': event.newSize.height,
    };
  } else if (event is SetPositionEvent) {
    base['newPosition'] = {
      'x': event.newPosition.x,
      'y': event.newPosition.y,
    };
  } else if (event is SetStateEvent) {
    base['newState'] = event.newState;
  } else if (event is AddChildEvent) {
    base['child'] = _serializeNode(event.child);
    if (event.index != null) {
      base['index'] = event.index;
    }
  } else if (event is RemoveChildEvent) {
    base['childId'] = event.childId;
  } else if (event is MoveChildEvent) {
    base['fromIndex'] = event.fromIndex;
    base['toIndex'] = event.toIndex;
  }

  return base;
}

Map<String, dynamic> _readMap(
  Map<String, dynamic> json,
  List<String> keys,
  String context,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  throw FormatException('$context requires one of: ${keys.join(', ')}');
}

int _readInt(
  Map<String, dynamic> json,
  List<String> keys,
  String context,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
  }
  throw FormatException('$context requires one of: ${keys.join(', ')}');
}

Node _parseNode(Map<String, dynamic> json) {
  final id = json['id'] as String?;
  final type = json['type'] as String?;
  if (id == null || type == null) {
    throw FormatException('Node requires "id" and "type"');
  }

  final sizeJson = _readOptionalMap(json['size']);
  final positionJson = _readOptionalMap(json['position']);
  final stateJson = _readOptionalMap(json['state']);

  List<Node>? children;
  final rawChildren = json['children'];
  if (rawChildren is List) {
    final parsedChildren = <Node>[];
    for (final entry in rawChildren) {
      if (entry is Map<String, dynamic>) {
        parsedChildren.add(_parseNode(entry));
      }
    }
    if (parsedChildren.isNotEmpty) {
      children = parsedChildren;
    }
  }

  return createNode(
    id: id,
    type: type,
    size: sizeJson != null ? parseSize(sizeJson) : null,
    position: positionJson != null ? parsePosition(positionJson) : null,
    children: children,
    state: stateJson != null ? Map<String, dynamic>.from(stateJson) : null,
  );
}

Map<String, dynamic> _serializeNode(Node node) {
  final data = <String, dynamic>{
    'id': node.id,
    'type': nodeTypeToString(node.type),
  };

  if (node.size != null) {
    data['size'] = {
      'w': node.size!.width,
      'h': node.size!.height,
    };
  }

  if (node.position != null) {
    data['position'] = {
      'x': node.position!.x,
      'y': node.position!.y,
    };
  }

  if (node.state.isNotEmpty) {
    data['state'] = node.state;
  }

  return data;
}

Map<String, dynamic>? _readOptionalMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

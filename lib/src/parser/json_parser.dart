// 🎯 Dart imports:
import 'dart:convert';

// 🌎 Project imports:
import 'package:mini_ui/src/models/event.dart';
import 'package:mini_ui/src/models/node.dart';

/// Parser for converting JSON input to node trees and events.
class JsonParser {
  /// Convert NodeType to string.
  String _nodeTypeToString(NodeType type) {
    switch (type) {
      case NodeType.box:
        return 'Box';
      case NodeType.row:
        return 'Row';
      case NodeType.column:
        return 'Column';
      case NodeType.stack:
        return 'Stack';
    }
  }

  /// Parse a JSON string into a ParsedInput.
  ParsedInput parse(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return parseJson(json);
  }

  /// Parse a JSON map into a ParsedInput.
  ParsedInput parseJson(Map<String, dynamic> json) {
    final treeJson = json['tree'] as Map<String, dynamic>;
    final eventsJson = json['events'] as List<dynamic>? ?? [];

    final root = _parseTree(treeJson);
    final events = _parseEvents(eventsJson);

    return ParsedInput(root: root, events: events);
  }

  /// Parse the tree structure from JSON.
  Node _parseTree(Map<String, dynamic> treeJson) {
    final rootId = treeJson['root'] as String;
    final nodesJson = treeJson['nodes'] as Map<String, dynamic>;

    // Create all nodes first
    final nodes = <String, Node>{};
    for (final entry in nodesJson.entries) {
      final nodeId = entry.key;
      final nodeData = entry.value as Map<String, dynamic>;
      nodes[nodeId] = _createNode(nodeId, nodeData);
    }

    // Build parent-child relationships
    for (final entry in nodesJson.entries) {
      final nodeId = entry.key;
      final nodeData = entry.value as Map<String, dynamic>;
      final childrenIds = nodeData['children'] as List<dynamic>? ?? [];

      for (final childId in childrenIds) {
        final parent = nodes[nodeId]!;
        final child = nodes[childId as String]!;
        parent.addChild(child);
      }
    }

    return nodes[rootId]!;
  }

  /// Create a node from JSON data.
  Node _createNode(String id, Map<String, dynamic> data) {
    final type = data['type'] as String;
    final sizeJson = data['size'] as Map<String, dynamic>?;
    final positionJson = data['position'] as Map<String, dynamic>?;
    final stateJson = data['state'] as Map<String, dynamic>?;

    final size = sizeJson != null
        ? Size(
            width: (sizeJson['w'] as num).toDouble(),
            height: (sizeJson['h'] as num).toDouble(),
          )
        : null;

    final position = positionJson != null
        ? Position(
            x: (positionJson['x'] as num).toDouble(),
            y: (positionJson['y'] as num).toDouble(),
          )
        : null;

    final state = stateJson != null ? Map<String, dynamic>.from(stateJson) : null;

    switch (type) {
      case 'Box':
        return BoxNode(
          id: id,
          size: size,
          position: position,
          state: state,
        );
      case 'Row':
        return RowNode(
          id: id,
          size: size,
          position: position,
          state: state,
        );
      case 'Column':
        return ColumnNode(
          id: id,
          size: size,
          position: position,
          state: state,
        );
      case 'Stack':
        return StackNode(
          id: id,
          size: size,
          position: position,
          state: state,
        );
      default:
        throw ArgumentError('Unknown node type: $type');
    }
  }

  /// Parse the events list from JSON.
  List<Event> _parseEvents(List<dynamic> eventsJson) {
    return eventsJson.map((eventJson) => _parseEvent(eventJson as Map<String, dynamic>)).toList();
  }

  /// Parse a single event from JSON.
  Event _parseEvent(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final targetId = json['target'] as String;

    switch (type) {
      case 'setSize':
        final sizeJson = json['newSize'] as Map<String, dynamic>;
        return SetSizeEvent(
          targetId: targetId,
          newSize: Size(
            width: (sizeJson['w'] as num).toDouble(),
            height: (sizeJson['h'] as num).toDouble(),
          ),
        );

      case 'setPosition':
        final positionJson = json['newPosition'] as Map<String, dynamic>;
        return SetPositionEvent(
          targetId: targetId,
          newPosition: Position(
            x: (positionJson['x'] as num).toDouble(),
            y: (positionJson['y'] as num).toDouble(),
          ),
        );

      case 'setState':
        final newState = json['newState'] as Map<String, dynamic>;
        return SetStateEvent(
          targetId: targetId,
          newState: Map<String, dynamic>.from(newState),
        );

      case 'addChild':
        final childJson = json['child'] as Map<String, dynamic>;
        final childId = childJson['id'] as String;
        final child = _createNode(childId, childJson);
        return AddChildEvent(
          targetId: targetId,
          child: child,
        );

      case 'removeChild':
        final childId = json['childId'] as String;
        return RemoveChildEvent(
          targetId: targetId,
          childId: childId,
        );

      case 'moveChild':
        final fromIndex = json['fromIndex'] as int;
        final toIndex = json['toIndex'] as int;
        return MoveChildEvent(
          targetId: targetId,
          fromIndex: fromIndex,
          toIndex: toIndex,
        );

      default:
        throw ArgumentError('Unknown event type: $type');
    }
  }

  /// Serialize a node tree to JSON.
  Map<String, dynamic> serializeTree(Node root) {
    final nodes = <String, Map<String, dynamic>>{};
    _collectNodes(root, nodes);

    return {
      'root': root.id,
      'nodes': nodes,
    };
  }

  /// Collect all nodes in the tree for serialization.
  void _collectNodes(Node node, Map<String, Map<String, dynamic>> nodes) {
    final nodeData = <String, dynamic>{
      'type': _nodeTypeToString(node.type),
    };

    if (node.size != null) {
      nodeData['size'] = {
        'w': node.size!.width,
        'h': node.size!.height,
      };
    }

    if (node.position != null) {
      nodeData['position'] = {
        'x': node.position!.x,
        'y': node.position!.y,
      };
    }

    if (node.state.isNotEmpty) {
      nodeData['state'] = node.state;
    }

    if (node.children.isNotEmpty) {
      nodeData['children'] = node.children.map((child) => child.id).toList();
    }

    nodes[node.id] = nodeData;

    // Recursively collect children
    for (final child in node.children) {
      _collectNodes(child, nodes);
    }
  }

  /// Serialize events to JSON.
  List<Map<String, dynamic>> serializeEvents(List<Event> events) {
    return events.map((event) => _serializeEvent(event)).toList();
  }

  /// Serialize a single event to JSON.
  Map<String, dynamic> _serializeEvent(Event event) {
    if (event is SetSizeEvent) {
      return {
        'type': 'setSize',
        'target': event.targetId,
        'newSize': {
          'w': event.newSize.width,
          'h': event.newSize.height,
        },
      };
    } else if (event is SetPositionEvent) {
      return {
        'type': 'setPosition',
        'target': event.targetId,
        'newPosition': {
          'x': event.newPosition.x,
          'y': event.newPosition.y,
        },
      };
    } else if (event is SetStateEvent) {
      return {
        'type': 'setState',
        'target': event.targetId,
        'newState': event.newState,
      };
    } else if (event is AddChildEvent) {
      final childNodes = <String, Map<String, dynamic>>{};
      _collectNodes(event.child, childNodes);
      final childData = childNodes[event.child.id]!;
      childData['id'] = event.child.id;

      return {
        'type': 'addChild',
        'target': event.targetId,
        'child': childData,
      };
    } else if (event is RemoveChildEvent) {
      return {
        'type': 'removeChild',
        'target': event.targetId,
        'childId': event.childId,
      };
    } else if (event is MoveChildEvent) {
      return {
        'type': 'moveChild',
        'target': event.targetId,
        'fromIndex': event.fromIndex,
        'toIndex': event.toIndex,
      };
    } else {
      throw ArgumentError('Unknown event type: ${event.runtimeType}');
    }
  }

  /// Serialize complete input to JSON.
  Map<String, dynamic> serializeInput(ParsedInput input) {
    return {
      'tree': serializeTree(input.root),
      'events': serializeEvents(input.events),
    };
  }
}

/// Parsed input containing root node and events.
class ParsedInput {
  /// The root node of the tree.
  final Node root;

  /// The list of events to process.
  final List<Event> events;

  ParsedInput({
    required this.root,
    required this.events,
  });

  @override
  String toString() {
    return 'ParsedInput(root: ${root.id}, events: ${events.length})';
  }
}

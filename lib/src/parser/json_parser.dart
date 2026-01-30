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

    if (nodesJson.isEmpty) {
      throw FormatException('Tree nodes must not be empty');
    }

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
        if (childId is! String) {
          throw FormatException('Child id for node $nodeId must be a string');
        }
        final child = nodes[childId];
        if (child == null) {
          throw FormatException('Child node "$childId" referenced by "$nodeId" not found');
        }
        parent.addChild(child);
      }
    }

    final root = nodes[rootId];
    if (root == null) {
      throw FormatException('Root node "$rootId" not found in nodes map');
    }

    return root;
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
    return createEvent(json);
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
    return events.map(eventToJson).toList();
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

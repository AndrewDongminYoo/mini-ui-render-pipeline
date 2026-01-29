// 🎯 Dart imports:
import 'dart:convert';

// 🌎 Project imports:
import 'package:mini_ui/render_pipeline.dart';

/// Complex example demonstrating nested layouts and multiple event types.
void main() {
  print('=== Complex UI Layout Example ===\n');

  // Create a more complex UI tree:
  // App (Column)
  //   ├── Header (Row)
  //   │   ├── Logo (Box)
  //   │   └── Nav (Row)
  //   │       ├── NavItem1 (Box)
  //   │       └── NavItem2 (Box)
  //   └── Body (Column)
  //       ├── Content (Box)
  //       └── Footer (Box)

  final inputJson = jsonEncode({
    'tree': {
      'root': 'App',
      'nodes': {
        'App': {
          'type': 'Column',
          'children': ['Header', 'Body'],
        },
        'Header': {
          'type': 'Row',
          'children': ['Logo', 'Nav'],
        },
        'Logo': {
          'type': 'Box',
          'size': {'w': 100, 'h': 50},
        },
        'Nav': {
          'type': 'Row',
          'children': ['NavItem1', 'NavItem2'],
        },
        'NavItem1': {
          'type': 'Box',
          'size': {'w': 80, 'h': 30},
        },
        'NavItem2': {
          'type': 'Box',
          'size': {'w': 80, 'h': 30},
        },
        'Body': {
          'type': 'Column',
          'children': ['Content', 'Footer'],
        },
        'Content': {
          'type': 'Box',
          'size': {'w': 300, 'h': 400},
        },
        'Footer': {
          'type': 'Box',
          'size': {'w': 300, 'h': 50},
        },
      },
    },
    'events': [
      // Event 1: Resize logo
      {
        'type': 'setSize',
        'target': 'Logo',
        'newSize': {'w': 150, 'h': 50},
      },
      // Event 2: Add new nav item
      {
        'type': 'addChild',
        'target': 'Nav',
        'child': {
          'id': 'NavItem3',
          'type': 'Box',
          'size': {'w': 80, 'h': 30},
        },
      },
      // Event 3: Resize content
      {
        'type': 'setSize',
        'target': 'Content',
        'newSize': {'w': 350, 'h': 450},
      },
      // Event 4: Remove footer
      {
        'type': 'removeChild',
        'target': 'Body',
        'childId': 'Footer',
      },
    ],
  });

  print('Initial Tree Structure:');
  _printTree(jsonDecode(inputJson)['tree'] as Map<String, dynamic>);
  print('\n${'=' * 60}\n');

  // Process through pipeline
  final pipeline = RenderPipeline();
  final outputJson = pipeline.processJson(inputJson);
  final output = jsonDecode(outputJson) as List;

  // Analyze each event
  final events = [
    'Resize Logo: 100x50 → 150x50',
    'Add NavItem3 to Nav',
    'Resize Content: 300x400 → 350x450',
    'Remove Footer from Body',
  ];

  for (int i = 0; i < output.length; i++) {
    final result = output[i];
    print('Event $i: ${events[i]}');
    print('─' * 60);
    print('Structure dirty: ${result['recomputeStructure']}');
    print('Layout dirty:    ${result['recomputeLayout']}');
    print('Paint order:     ${result['paintOrder']}');
    print('\n${'=' * 60}\n');
  }

  // Show final state
  print('Final Paint Order:');
  final finalPaintOrder = output.last['paintOrder'] as List;
  for (int i = 0; i < finalPaintOrder.length; i++) {
    print('  ${i + 1}. ${finalPaintOrder[i]}');
  }
}

void _printTree(Map<String, dynamic> tree) {
  final rootId = tree['root'] as String;
  final nodes = tree['nodes'] as Map<String, dynamic>;

  void printNode(String nodeId, String prefix, String childrenPrefix) {
    final node = nodes[nodeId] as Map<String, dynamic>;
    final type = node['type'] as String;
    final size = node['size'] as Map<String, dynamic>?;
    final children = node['children'] as List?;

    final sizeStr = size != null ? ' (${size['w']}x${size['h']})' : '';
    print('$prefix$nodeId [$type]$sizeStr');

    if (children != null && children.isNotEmpty) {
      for (int i = 0; i < children.length - 1; i++) {
        printNode(
          children[i] as String,
          '$childrenPrefix├── ',
          '$childrenPrefix│   ',
        );
      }
      printNode(
        children.last as String,
        '$childrenPrefix└── ',
        '$childrenPrefix    ',
      );
    }
  }

  printNode(rootId, '', '');
}

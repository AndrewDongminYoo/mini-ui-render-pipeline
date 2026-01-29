// 🎯 Dart imports:
import 'dart:convert';

// 🌎 Project imports:
import 'package:mini_ui/render_pipeline.dart';

/// Simple example demonstrating basic usage of the Mini UI Render Pipeline.
void main() {
  print('=== Mini UI Render Pipeline Example ===\n');

  // Create a simple UI tree with a Row containing two Boxes
  final inputJson = jsonEncode({
    'tree': {
      'root': 'R',
      'nodes': {
        'R': {
          'type': 'Row',
          'children': ['A', 'B'],
        },
        'A': {
          'type': 'Box',
          'size': {'w': 50, 'h': 20},
        },
        'B': {
          'type': 'Box',
          'size': {'w': 30, 'h': 20},
        },
      },
    },
    'events': [
      // Event 1: Resize Box A
      {
        'type': 'setSize',
        'target': 'A',
        'newSize': {'w': 100, 'h': 30},
      },
      // Event 2: Add a new Box C
      {
        'type': 'addChild',
        'target': 'R',
        'child': {
          'id': 'C',
          'type': 'Box',
          'size': {'w': 40, 'h': 25},
        },
      },
    ],
  });

  print('Input:');
  print(const JsonEncoder.withIndent('  ').convert(jsonDecode(inputJson)));
  print('\n${'=' * 50}\n');

  // Process through pipeline
  final pipeline = RenderPipeline();
  final outputJson = pipeline.processJson(inputJson);
  final output = jsonDecode(outputJson) as List;

  print('Output:');
  print(const JsonEncoder.withIndent('  ').convert(output));
  print('\n${'=' * 50}\n');

  // Analyze results
  print('Analysis:');
  for (int i = 0; i < output.length; i++) {
    final result = output[i];
    print('\nAfter Event $i:');
    print('  Structure changes: ${result['recomputeStructure']}');
    print('  Layout changes: ${result['recomputeLayout']}');
    print('  Paint order: ${result['paintOrder']}');
  }
}

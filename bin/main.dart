// 🎯 Dart imports:
import 'dart:convert';
import 'dart:io';

// 🌎 Project imports:
import 'package:mini_ui/render_pipeline.dart';

void main(List<String> arguments) async {
  // Parse arguments
  if (arguments.isEmpty || arguments.contains('-h') || arguments.contains('--help')) {
    _printHelp();
    exit(0);
  }

  if (arguments.contains('-v') || arguments.contains('--version')) {
    _printVersion();
    exit(0);
  }

  try {
    // Read input
    final inputJson = await _readInput(arguments);

    // Process through pipeline
    final pipeline = RenderPipeline();
    final outputJson = pipeline.processJson(inputJson);

    // Write output
    await _writeOutput(outputJson, arguments);

    exit(0);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

/// Read input from file or stdin
Future<String> _readInput(List<String> arguments) async {
  // Check for -i or --input flag
  final inputIndex = _findArgIndex(arguments, ['-i', '--input']);

  if (inputIndex != -1 && inputIndex + 1 < arguments.length) {
    // Read from file
    final filePath = arguments[inputIndex + 1];
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Input file not found: $filePath');
    }

    return await file.readAsString();
  } else if (arguments.isNotEmpty && !arguments[0].startsWith('-')) {
    // First non-flag argument is input file
    final filePath = arguments[0];
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Input file not found: $filePath');
    }

    return await file.readAsString();
  } else {
    // Read from stdin
    final lines = <String>[];
    await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      lines.add(line);
    }
    return lines.join('\n');
  }
}

/// Write output to file or stdout
Future<void> _writeOutput(String output, List<String> arguments) async {
  // Check for -o or --output flag
  final outputIndex = _findArgIndex(arguments, ['-o', '--output']);

  if (outputIndex != -1 && outputIndex + 1 < arguments.length) {
    // Write to file
    final filePath = arguments[outputIndex + 1];
    final file = File(filePath);
    await file.writeAsString(output);
  } else {
    // Write to stdout
    stdout.writeln(output);
  }
}

/// Find index of any of the given flags
int _findArgIndex(List<String> arguments, List<String> flags) {
  for (final flag in flags) {
    final index = arguments.indexOf(flag);
    if (index != -1) {
      return index;
    }
  }
  return -1;
}

/// Print help message
void _printHelp() {
  print('''
Mini UI Render Pipeline

A tool for processing UI tree structures and state change events to determine
structure changes, layout recomputation, and paint order.

USAGE:
  mini_ui [OPTIONS] [INPUT_FILE]

OPTIONS:
  -i, --input <FILE>    Input JSON file (default: stdin)
  -o, --output <FILE>   Output JSON file (default: stdout)
  -h, --help            Print help information
  -v, --version         Print version information

EXAMPLES:
  # Read from file, write to stdout
  mini_ui input.json

  # Read from stdin, write to file
  cat input.json | mini_ui -o output.json

  # Read from file, write to file
  mini_ui -i input.json -o output.json

  # Using flags explicitly
  mini_ui --input input.json --output output.json

INPUT FORMAT:
  {
    "tree": {
      "root": "nodeId",
      "nodes": {
        "nodeId": {
          "type": "Row|Column|Box|Stack",
          "children": ["childId"],
          "size": {"w": 100, "h": 50},
          "position": {"x": 0, "y": 0},
          "state": {}
        }
      }
    },
    "events": [
      {"type": "eventType", "target": "nodeId", ...params}
    ]
  }

OUTPUT FORMAT:
  [
    {
      "afterEvent": 0,
      "recomputeStructure": ["nodeId"],
      "recomputeLayout": ["nodeId"],
      "paintOrder": ["nodeId"]
    }
  ]

For more information, visit: https://github.com/AndrewDongminYoo/apr-app-assignment
''');
}

/// Print version information
void _printVersion() {
  print('Mini UI Render Pipeline v1.0.0');
}

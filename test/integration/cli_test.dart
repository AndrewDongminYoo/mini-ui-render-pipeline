// 🎯 Dart imports:
import 'dart:convert';
import 'dart:io';

// 📦 Package imports:
import 'package:test/test.dart';

void main() {
  group('CLI', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mini_ui_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should show help with -h flag', () async {
      final result = await Process.run('dart', ['run', 'bin/main.dart', '-h']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Mini UI Render Pipeline'));
      expect(result.stdout.toString(), contains('USAGE:'));
      expect(result.stdout.toString(), contains('OPTIONS:'));
    });

    test('should show help with --help flag', () async {
      final result = await Process.run('dart', ['run', 'bin/main.dart', '--help']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Mini UI Render Pipeline'));
    });

    test('should show version with -v flag', () async {
      final result = await Process.run('dart', ['run', 'bin/main.dart', '-v']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Mini UI Render Pipeline v1.0.0'));
    });

    test('should show version with --version flag', () async {
      final result = await Process.run('dart', ['run', 'bin/main.dart', '--version']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('v1.0.0'));
    });

    test('should process input file and output to stdout', () async {
      // Create input file
      final inputFile = File('${tempDir.path}/input.json');
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {
              'type': 'Box',
              'size': {'w': 50, 'h': 20},
            },
          },
        },
        'events': [
          {
            'type': 'setSize',
            'target': 'R',
            'newSize': {'w': 100, 'h': 30},
          },
        ],
      });
      await inputFile.writeAsString(inputJson);

      // Run CLI
      final result = await Process.run('dart', ['run', 'bin/main.dart', inputFile.path]);

      expect(result.exitCode, 0);

      // Parse output
      final output = jsonDecode(result.stdout.toString().trim()) as List;
      expect(output.length, 1);
      expect(output[0]['afterEvent'], 0);
      expect(output[0]['recomputeLayout'], isA<List>());
      expect(output[0]['paintOrder'], isA<List>());
    });

    test('should process input file with -i flag', () async {
      // Create input file
      final inputFile = File('${tempDir.path}/input.json');
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {'type': 'Box'},
          },
        },
        'events': [],
      });
      await inputFile.writeAsString(inputJson);

      // Run CLI
      final result = await Process.run('dart', ['run', 'bin/main.dart', '-i', inputFile.path]);

      expect(result.exitCode, 0);

      // Parse output
      final output = jsonDecode(result.stdout.toString().trim()) as List;
      expect(output, isEmpty);
    });

    test('should write output to file with -o flag', () async {
      // Create input file
      final inputFile = File('${tempDir.path}/input.json');
      final outputFile = File('${tempDir.path}/output.json');
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {
              'type': 'Box',
              'size': {'w': 50, 'h': 20},
            },
          },
        },
        'events': [
          {
            'type': 'setSize',
            'target': 'R',
            'newSize': {'w': 100, 'h': 30},
          },
        ],
      });
      await inputFile.writeAsString(inputJson);

      // Run CLI
      final result = await Process.run(
        'dart',
        ['run', 'bin/main.dart', inputFile.path, '-o', outputFile.path],
      );

      expect(result.exitCode, 0);

      // Read output file
      expect(await outputFile.exists(), true);
      final outputContent = await outputFile.readAsString();
      final output = jsonDecode(outputContent) as List;
      expect(output.length, 1);
    });

    test('should use --input and --output flags', () async {
      // Create input file
      final inputFile = File('${tempDir.path}/input.json');
      final outputFile = File('${tempDir.path}/output.json');
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {'type': 'Row'},
          },
        },
        'events': [
          {
            'type': 'addChild',
            'target': 'R',
            'child': {
              'id': 'A',
              'type': 'Box',
            },
          },
        ],
      });
      await inputFile.writeAsString(inputJson);

      // Run CLI
      final result = await Process.run(
        'dart',
        ['run', 'bin/main.dart', '--input', inputFile.path, '--output', outputFile.path],
      );

      expect(result.exitCode, 0);

      // Read output file
      final outputContent = await outputFile.readAsString();
      final output = jsonDecode(outputContent) as List;
      expect(output.length, 1);
      expect(output[0]['recomputeStructure'], isA<List>());
    });

    test('should handle non-existent input file', () async {
      final result = await Process.run('dart', ['run', 'bin/main.dart', 'nonexistent.json']);

      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('Error'));
      expect(result.stderr.toString(), contains('not found'));
    });

    test('should handle invalid JSON input', () async {
      // Create invalid input file
      final inputFile = File('${tempDir.path}/invalid.json');
      await inputFile.writeAsString('invalid json');

      // Run CLI
      final result = await Process.run('dart', ['run', 'bin/main.dart', inputFile.path]);

      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('Error'));
    });

    test('should process complex tree structure', () async {
      // Create input file with complex tree
      final inputFile = File('${tempDir.path}/complex.json');
      final inputJson = jsonEncode({
        'tree': {
          'root': 'R',
          'nodes': {
            'R': {
              'type': 'Column',
              'children': ['A', 'B'],
            },
            'A': {
              'type': 'Row',
              'children': ['A1', 'A2'],
            },
            'A1': {
              'type': 'Box',
              'size': {'w': 30, 'h': 20},
            },
            'A2': {
              'type': 'Box',
              'size': {'w': 20, 'h': 20},
            },
            'B': {
              'type': 'Box',
              'size': {'w': 50, 'h': 30},
            },
          },
        },
        'events': [
          {
            'type': 'setSize',
            'target': 'A1',
            'newSize': {'w': 60, 'h': 20},
          },
          {
            'type': 'removeChild',
            'target': 'R',
            'childId': 'B',
          },
        ],
      });
      await inputFile.writeAsString(inputJson);

      // Run CLI
      final result = await Process.run('dart', ['run', 'bin/main.dart', inputFile.path]);

      expect(result.exitCode, 0);

      // Parse output
      final output = jsonDecode(result.stdout.toString().trim()) as List;
      expect(output.length, 2);

      // First event: setSize
      expect(output[0]['afterEvent'], 0);
      expect(output[0]['recomputeLayout'], isA<List>());

      // Second event: removeChild
      expect(output[1]['afterEvent'], 1);
      expect(output[1]['recomputeStructure'], isA<List>());
    });
  });
}

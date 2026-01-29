// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:mini_ui/mini_ui.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}

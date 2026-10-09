import 'dart:io';
import 'package:codrel/codrel.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ArchitectureAdapter tests', () {
    const sampleCode = '''
import 'package:flutter/material.dart';

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';

    test('adapts to vanilla keeping StatefulWidget intact', () {
      final result = ArchitectureAdapter.adapt(
        rawCode: sampleCode,
        componentId: 'test-widget',
        architecture: 'vanilla',
      );
      expect(result, contains('class TestWidget extends StatefulWidget'));
      expect(
          result, contains('class _TestWidgetState extends State<TestWidget>'));
    });

    test('adapts to riverpod with ConsumerState and provider', () {
      final result = ArchitectureAdapter.adapt(
        rawCode: sampleCode,
        componentId: 'test-widget',
        architecture: 'riverpod',
      );
      expect(
          result, contains('package:flutter_riverpod/flutter_riverpod.dart'));
      expect(result, contains('ConsumerStatefulWidget'));
      expect(result, contains('ConsumerState<TestWidget>'));
      expect(
          result, contains('class TestWidgetNotifier extends StateNotifier'));
      expect(result, contains('final test_widgetProvider ='));
    });

    test('adapts to getx with GetxController', () {
      final result = ArchitectureAdapter.adapt(
        rawCode: sampleCode,
        componentId: 'test-widget',
        architecture: 'getx',
      );
      expect(result, contains('package:get/get.dart'));
      expect(result,
          contains('class TestWidgetController extends GetxController'));
      expect(result, contains('.obs'));
    });

    test('adapts to bloc with Cubit', () {
      final result = ArchitectureAdapter.adapt(
        rawCode: sampleCode,
        componentId: 'test-widget',
        architecture: 'bloc',
      );
      expect(result, contains('package:flutter_bloc/flutter_bloc.dart'));
      expect(result,
          contains('class TestWidgetCubit extends Cubit<TestWidgetState>'));
    });
  });

  group('CodrelCommandRunner CLI execution tests', () {
    late Directory tempDir;
    late CodrelCommandRunner runner;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('codrel_cli_test_');
      runner = CodrelCommandRunner();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      runner.client.close();
    });

    test('--version outputs version successfully', () async {
      final code = await runner.run(['--version']);
      expect(code, equals(0));
    });

    test('list command executes successfully', () async {
      final code = await runner.run(['list']);
      expect(code, equals(0));
    });

    test('info command displays component details', () async {
      final code = await runner.run(['info', 'swipe-deck']);
      expect(code, equals(0));
    });

    test('info command fails gracefully for invalid slug', () async {
      final code = await runner.run(['info', 'invalid-slug-xyz']);
      expect(code, equals(1));
    });

    test('add command with --dry-run previews without writing to disk',
        () async {
      final code = await runner.run(['add', 'swipe-deck', '--dry-run']);
      expect(code, equals(0));
      final files = tempDir.listSync();
      expect(files, isEmpty);
    });

    test('add command writes component file to designated directory', () async {
      final code = await runner.run([
        'add',
        'swipe-deck',
        '--dir',
        tempDir.path,
      ]);
      expect(code, equals(0));

      final generatedFile = File(p.join(tempDir.path, 'swipe_card_deck.dart'));
      expect(generatedFile.existsSync(), isTrue);
      final content = generatedFile.readAsStringSync();
      expect(content, isNotEmpty);
      expect(content, contains('class SwipeCardDeck'));
    });

    test('add command prevents overwrite unless --overwrite is passed',
        () async {
      // First write
      final firstCode = await runner.run([
        'add',
        'swipe-deck',
        '--dir',
        tempDir.path,
      ]);
      expect(firstCode, equals(0));

      // Second write without --overwrite should fail
      final secondCode = await runner.run([
        'add',
        'swipe-deck',
        '--dir',
        tempDir.path,
      ]);
      expect(secondCode, equals(1));

      // With --overwrite should succeed
      final thirdCode = await runner.run([
        'add',
        'swipe-deck',
        '--dir',
        tempDir.path,
        '--overwrite',
      ]);
      expect(thirdCode, equals(0));
    });

    test('add command adapts to Riverpod architecture', () async {
      final code = await runner.run([
        'add',
        'smart-otp',
        '--dir',
        tempDir.path,
        '--arch',
        'riverpod',
      ]);
      expect(code, equals(0));

      final generatedFile = File(p.join(tempDir.path, 'smart_otp_input.dart'));
      expect(generatedFile.existsSync(), isTrue);
      final content = generatedFile.readAsStringSync();
      expect(content, contains('flutter_riverpod'));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:codrel/codrel.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ComponentExporter', () {
    const appStyleSource = """import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/context_extension.dart';

class Demo extends StatelessWidget {
  const Demo({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.isDark ? AppColors.darkBg : AppColors.termYellow,
    );
  }
}
""";

    test('removes internal imports and inlines only used tokens', () {
      final out = ComponentExporter.makeSelfContained(appStyleSource);
      expect(out, isNot(contains('core/constants')));
      expect(out, isNot(contains('context_extension.dart')));
      expect(out, isNot(contains('AppColors.')));
      expect(out, contains('abstract final class _CodrelColors'));
      expect(out, contains('static const Color darkBg = Color(0xFF0A0B0E);'));
      expect(out, contains('static const Color termYellow'));
      expect(out, isNot(contains('static const Color lightBg')));
      expect(out, contains('extension _CodrelContext on BuildContext'));
      expect(out, contains('bool get isDark'));
      expect(out, isNot(contains('get textTheme')));
      expect(out.indexOf('_CodrelColors {'),
          greaterThan(out.indexOf("import 'package:flutter/material.dart';")));
    });

    test('is idempotent', () {
      final once = ComponentExporter.makeSelfContained(appStyleSource);
      expect(ComponentExporter.makeSelfContained(once), equals(once));
    });

    test('rejects unknown project-internal imports', () {
      const source = """import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';

class X {}
""";
      expect(() => ComponentExporter.makeSelfContained(source),
          throwsA(isA<ExportException>()));
    });

    test('rejects unknown color tokens', () {
      const source = """import 'package:flutter/material.dart';
const c = AppColors.doesNotExist;
""";
      expect(() => ComponentExporter.makeSelfContained(source),
          throwsA(isA<ExportException>()));
    });

    test('parses tokens from an AppColors source file', () {
      final tokens = ComponentExporter.parseColorTokens(
        'static const Color accent = Color(0xFF5E6AD2);\n'
        'static const Color transparent = Colors.transparent;',
      );
      expect(tokens, {
        'accent': 'Color(0xFF5E6AD2)',
        'transparent': 'Colors.transparent',
      });
    });

    test('default tokens mirror the Codrel app palette', () {
      final appColors =
          File('../codrel_app/lib/core/constants/app_colors.dart');
      if (!appColors.existsSync()) return;
      expect(
        ComponentExporter.parseColorTokens(appColors.readAsStringSync()),
        equals(ComponentExporter.defaultColorTokens),
      );
    });
  });

  group('RegistryClient.isValidSlug', () {
    test('accepts kebab-case slugs and rejects injection attempts', () {
      expect(RegistryClient.isValidSlug('swipe-deck'), isTrue);
      expect(RegistryClient.isValidSlug('card-flip-3d'), isTrue);
      expect(RegistryClient.isValidSlug('a&select=*'), isFalse);
      expect(RegistryClient.isValidSlug('../etc'), isFalse);
      expect(RegistryClient.isValidSlug(''), isFalse);
    });
  });

  group('CodrelCommandRunner', () {
    late Directory tempDir;
    late CodrelCommandRunner runner;

    const vanillaSource = """import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SwipeCardDeck extends StatelessWidget {
  const SwipeCardDeck({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(color: AppColors.accent);
}
""";

    const riverpodVariant = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwipeCardDeck extends ConsumerWidget {
  const SwipeCardDeck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox();
}
""";

    const legacyRiverpodVariant =
        """import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeckNotifier extends StateNotifier<int> {
  DeckNotifier() : super(0);
}
""";

    Map<String, dynamic> row({Map<String, String> variants = const {}}) => {
          'id': 'swipe-deck',
          'name': 'Swipe Card Deck',
          'file_name': 'swipe_card_deck.dart',
          'description': 'Cards',
          'complexity': 'Intermediate',
          'tags': ['gestures'],
          'downloads_count': 3,
          'code_template': vanillaSource,
          'architecture_templates': variants,
        };

    CodrelCommandRunner buildRunner({Map<String, String> variants = const {}}) {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/rpc/increment_downloads')) {
          return http.Response('', 204);
        }
        if (path.endsWith('/functions/v1/convert-architecture')) {
          return http.Response('{"error":"not published"}', 404);
        }
        if (path.endsWith('/rest/v1/components')) {
          final id = request.url.queryParameters['id'];
          final rows = id == null || id == 'eq.swipe-deck'
              ? [row(variants: variants)]
              : <Map<String, dynamic>>[];
          return http.Response(jsonEncode(rows), 200);
        }
        return http.Response('not found', 404);
      });
      return CodrelCommandRunner(
        client: RegistryClient(
          baseUrl: 'https://registry.test',
          apiKey: 'test',
          httpClient: mock,
        ),
      );
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('codrel_cli_test_');
      runner = buildRunner();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      runner.client.close();
    });

    test('--version succeeds', () async {
      expect(await runner.run(['--version']), 0);
    });

    test('list succeeds', () async {
      expect(await runner.run(['list']), 0);
    });

    test('info succeeds for a known slug and fails for unknown ones', () async {
      expect(await runner.run(['info', 'swipe-deck']), 0);
      expect(await runner.run(['info', 'invalid-slug-xyz']), 1);
      expect(await runner.run(['info', 'bad&slug']), 1);
    });

    test('--dry-run does not write to disk', () async {
      expect(await runner.run(['add', 'swipe-deck', '--dry-run']), 0);
      expect(tempDir.listSync(), isEmpty);
    });

    test('add writes a self-contained vanilla component', () async {
      expect(await runner.run(['add', 'swipe-deck', '--dir', tempDir.path]), 0);
      final content =
          File(p.join(tempDir.path, 'swipe_card_deck.dart')).readAsStringSync();
      expect(content, contains('class SwipeCardDeck'));
      expect(content, contains('_CodrelColors.accent'));
      expect(content, isNot(contains("import '../")));
    });

    test('add refuses to overwrite without --overwrite', () async {
      final args = ['add', 'swipe-deck', '--dir', tempDir.path];
      expect(await runner.run(args), 0);
      expect(await runner.run(args), 1);
      expect(await runner.run([...args, '--overwrite']), 0);
    });

    test('add installs a published architecture variant', () async {
      runner = buildRunner(variants: {'riverpod': riverpodVariant});
      final code = await runner.run(
          ['add', 'swipe-deck', '--dir', tempDir.path, '--arch', 'riverpod']);
      expect(code, 0);
      final content =
          File(p.join(tempDir.path, 'swipe_card_deck.dart')).readAsStringSync();
      expect(content, contains('ConsumerWidget'));
    });

    test('add fails without writing when a variant is not published', () async {
      final code = await runner
          .run(['add', 'swipe-deck', '--dir', tempDir.path, '--arch', 'bloc']);
      expect(code, 1);
      expect(tempDir.listSync(), isEmpty);
    });

    test('add rejects legacy Riverpod variants', () async {
      runner = buildRunner(variants: {'riverpod': legacyRiverpodVariant});
      final code = await runner.run(
          ['add', 'swipe-deck', '--dir', tempDir.path, '--arch', 'riverpod']);
      expect(code, 1);
      expect(tempDir.listSync(), isEmpty);
    });
  });
}

/// Thrown when component source cannot be turned into a standalone file.
class ExportException implements Exception {
  /// Why the source could not be exported.
  final String message;

  /// Creates an exception with [message].
  const ExportException(this.message);

  @override
  String toString() => message;
}

/// Converts Codrel component source into a single self-contained Dart file
/// that compiles inside any Flutter project without Codrel-internal imports.
class ComponentExporter {
  ComponentExporter._();

  /// Name of the private class that holds inlined color tokens.
  static const String colorsClassName = '_CodrelColors';

  /// Name of the private `BuildContext` extension that is inlined.
  static const String contextExtensionName = '_CodrelContext';

  /// Design tokens mirrored from the Codrel app (`AppColors`).
  static const Map<String, String> defaultColorTokens = {
    'transparent': 'Colors.transparent',
    'accent': 'Color(0xFF5E6AD2)',
    'accentDarkText': 'Color(0xFF8E98F2)',
    'accentLightText': 'Color(0xFF4338CA)',
    'accentSoftDark': 'Color(0x295E6AD2)',
    'accentSoftLight': 'Color(0x1F5E6AD2)',
    'glow': 'Color(0x805E6AD2)',
    'darkBg': 'Color(0xFF0A0B0E)',
    'darkSurface': 'Color(0xFF161922)',
    'darkStage': 'Color(0xFF0F1118)',
    'darkText': 'Color(0xFFFFFFFF)',
    'darkMuted': 'Color(0xFF94A3B8)',
    'darkBorder': 'Color(0x14FFFFFF)',
    'darkBorderStrong': 'Color(0x29FFFFFF)',
    'darkBorder2': 'Color(0x29FFFFFF)',
    'darkCode': 'Color(0xFF0D1117)',
    'darkDanger': 'Color(0xFFF87171)',
    'darkDot': 'Color(0x21FFFFFF)',
    'lightBg': 'Color(0xFFF4F5F9)',
    'lightSurface': 'Color(0xFFFFFFFF)',
    'lightStage': 'Color(0xFFEDEFF6)',
    'lightText': 'Color(0xFF0A0B0E)',
    'lightMuted': 'Color(0xFF5B6577)',
    'lightBorder': 'Color(0x170A0B0E)',
    'lightBorderStrong': 'Color(0x2E0A0B0E)',
    'lightBorder2': 'Color(0x2E0A0B0E)',
    'lightDanger': 'Color(0xFFDC2626)',
    'lightDot': 'Color(0x260A0B0E)',
    'success': 'Color(0xFF34D399)',
    'successLight': 'Color(0xFF059669)',
    'successDark': 'Color(0xFF34D399)',
    'danger': 'Color(0xFFF87171)',
    'dangerLight': 'Color(0xFFDC2626)',
    'warning': 'Color(0xFFF59E0B)',
    'info': 'Color(0xFF3B82F6)',
    'purple': 'Color(0xFF8B5CF6)',
    'pink': 'Color(0xFFEC4899)',
    'cyan': 'Color(0xFF06B6D4)',
    'slateDark': 'Color(0xFF1E293B)',
    'slateLight': 'Color(0xFFE2E8F0)',
    'overlayDark': 'Color(0xB30F121C)',
    'overlayLight': 'Color(0x33000000)',
    'deckDarkGradStart': 'Color(0xFF311042)',
    'deckDarkGradEnd': 'Color(0xFF1E112A)',
    'deckPurpleGradStart': 'Color(0xFF6D28D9)',
    'deckPurpleGradEnd': 'Color(0xFF4C1D95)',
    'deckBlueGradStart': 'Color(0xFF1E3A8A)',
    'deckBlueGradEnd': 'Color(0xFF172554)',
    'termRed': 'Color(0xFFFF5F56)',
    'termYellow': 'Color(0xFFFFBD2E)',
    'termGreen': 'Color(0xFF27C93F)',
    'termPromptGreen': 'Color(0xFF7EE0A8)',
    'darkCodeText': 'Color(0xFFE6EDF3)',
  };

  static const Map<String, String> _contextGetters = {
    'theme': 'ThemeData get theme => Theme.of(this);',
    'textTheme': 'TextTheme get textTheme => Theme.of(this).textTheme;',
    'colorScheme': 'ColorScheme get colorScheme => Theme.of(this).colorScheme;',
    'isDark':
        'bool get isDark => Theme.of(this).brightness == Brightness.dark;',
  };

  static const Set<String> _inlinableImports = {
    'app_colors.dart',
    'context_extension.dart',
  };

  static final RegExp _importPattern = RegExp(
      r'''^import\s+['"]([^'"]+)['"][^;]*;[ \t]*\r?\n?''',
      multiLine: true);
  static final RegExp _colorUsage = RegExp(r'\bAppColors\.(\w+)');
  static final RegExp _colorDeclaration =
      RegExp(r'static\s+const\s+Color\s+(\w+)\s*=\s*([^;]+);');

  /// Parses `static const Color name = value;` declarations from an
  /// `AppColors` source file.
  static Map<String, String> parseColorTokens(String source) {
    return {
      for (final m in _colorDeclaration.allMatches(source))
        m.group(1)!: m.group(2)!.trim(),
    };
  }

  /// Returns a standalone version of [source].
  ///
  /// Codrel-internal relative imports are removed and the tokens they
  /// provided are inlined as private declarations, so the result cannot
  /// collide with the host project's own `AppColors` or extensions.
  static String makeSelfContained(
    String source, {
    Map<String, String> colorTokens = defaultColorTokens,
  }) {
    var code = source.replaceAll('\r\n', '\n');

    final unsupported = <String>[];
    code = code.replaceAllMapped(_importPattern, (m) {
      final uri = m.group(1)!;
      if (uri.startsWith('dart:') || uri.startsWith('package:')) {
        return m.group(0)!;
      }
      final fileName = uri.split('/').last;
      if (!_inlinableImports.contains(fileName)) unsupported.add(uri);
      return '';
    });

    if (unsupported.isNotEmpty) {
      throw ExportException(
        'Component depends on project-internal files that cannot be exported: '
        '${unsupported.join(', ')}',
      );
    }

    final usedColors = <String>{
      for (final m in _colorUsage.allMatches(code)) m.group(1)!,
    };
    final missing = usedColors.where((c) => !colorTokens.containsKey(c));
    if (missing.isNotEmpty) {
      throw ExportException('Unknown color tokens: ${missing.join(', ')}');
    }
    code =
        code.replaceAllMapped(_colorUsage, (m) => '$colorsClassName.${m[1]}');

    final usedGetters = _contextGetters.keys
        .where((g) => RegExp('\\bcontext\\.$g\\b').hasMatch(code))
        .toList();

    final preamble = StringBuffer();
    if (usedColors.isNotEmpty && !code.contains('class $colorsClassName')) {
      preamble.writeln('abstract final class $colorsClassName {');
      for (final name in colorTokens.keys.where(usedColors.contains)) {
        preamble.writeln('  static const Color $name = ${colorTokens[name]};');
      }
      preamble.writeln('}');
    }
    if (usedGetters.isNotEmpty &&
        !code.contains('extension $contextExtensionName')) {
      if (preamble.isNotEmpty) preamble.writeln();
      preamble.writeln('extension $contextExtensionName on BuildContext {');
      for (final g in usedGetters) {
        preamble.writeln('  ${_contextGetters[g]}');
      }
      preamble.writeln('}');
    }

    code = code.replaceAll(RegExp(r'\n{3,}'), '\n\n').trimLeft();
    if (preamble.isEmpty) return '${code.trimRight()}\n';

    final imports = _importPattern.allMatches(code).toList();
    if (imports.isEmpty) {
      return '$preamble\n${code.trimRight()}\n';
    }
    final insertAt = imports.last.end;
    final head = code.substring(0, insertAt).trimRight();
    final tail = code.substring(insertAt).trimLeft();
    return '$head\n\n$preamble\n${tail.trimRight()}\n';
  }
}

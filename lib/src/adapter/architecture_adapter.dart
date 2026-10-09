/// Utility class for adapting component code to different state architectures.
class ArchitectureAdapter {
  /// Adapts raw component code to the requested state management architecture.
  static String adapt({
    required String rawCode,
    required String componentId,
    required String architecture,
  }) {
    final sanitized = _sanitizeImports(rawCode);

    switch (architecture.toLowerCase().trim()) {
      case 'riverpod':
        return _adaptToRiverpod(sanitized, componentId);
      case 'getx':
        return _adaptToGetX(sanitized, componentId);
      case 'bloc':
        return _adaptToBloc(sanitized, componentId);
      case 'vanilla':
      case 'normal':
      default:
        return sanitized;
    }
  }

  static String _sanitizeImports(String code) {
    var result = code;

    result = result.replaceAll(
      RegExp(r'''import\s+['"][^'"]*core/constants/app_colors\.dart['"];\n?'''),
      '',
    );
    result = result.replaceAll(
      RegExp(
          r'''import\s+['"][^'"]*core/utils/context_extension\.dart['"];\n?'''),
      '',
    );

    final needsColors = result.contains('AppColors.');
    final needsContextExt = result.contains('context.isDark') ||
        result.contains('context.textTheme') ||
        result.contains('context.colorScheme');

    final buffer = StringBuffer();

    if (needsColors && !result.contains('class AppColors')) {
      buffer.writeln('''
abstract class AppColors {
  static const Color accent = Color(0xFF6366F1);
  static const Color glow = Color(0xFF818CF8);
  static const Color success = Color(0xFF10B981);
  static const Color darkBg = Color(0xFF0B0F17);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF131B29);
  static const Color lightSurface = Colors.white;
  static const Color darkStage = Color(0xFF0F172A);
  static const Color lightStage = Color(0xFFF1F5F9);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color darkText = Colors.white;
  static const Color lightText = Color(0xFF0F172A);
  static const Color darkMuted = Color(0xFF94A3B8);
  static const Color lightMuted = Color(0xFF64748B);
}
''');
    }

    if (needsContextExt &&
        !result.contains('extension _CodrelContextExtension')) {
      buffer.writeln('''
extension _CodrelContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
''');
    }

    if (buffer.isNotEmpty) {
      final lastImport = result.lastIndexOf(RegExp(r'import\s+[^;]+;'));
      if (lastImport != -1) {
        final endOfImports = result.indexOf('\n', lastImport);
        result =
            '${result.substring(0, endOfImports + 1)}\n$buffer${result.substring(endOfImports + 1)}';
      } else {
        result = '$buffer\n$result';
      }
    }

    return result;
  }

  static String _pascalCase(String id) {
    return id
        .split(RegExp(r'[-_]'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }

  static String _adaptToRiverpod(String code, String id) {
    final className = _pascalCase(id);
    var modified = code;

    if (!modified.contains('flutter_riverpod.dart') &&
        !modified.contains('hooks_riverpod.dart')) {
      modified =
          "import 'package:flutter_riverpod/flutter_riverpod.dart';\n$modified";
    }

    modified = modified.replaceAll(
      'StatefulWidget',
      'ConsumerStatefulWidget',
    );
    modified = modified.replaceAllMapped(
      RegExp(r'State<([^>]+)>\s+createState\(\)\s*=>'),
      (match) => 'ConsumerState<${match[1]}> createState() =>',
    );
    modified = modified.replaceAllMapped(
      RegExp(r'class\s+(_?\w+State)\s+extends\s+State<([^>]+)>'),
      (match) => 'class ${match[1]} extends ConsumerState<${match[2]}>',
    );

    final providerSnippet = '''

class ${className}StateModel {
  final int activeIndex;
  final bool isExpanded;
  final Map<String, dynamic> metadata;

  const ${className}StateModel({
    this.activeIndex = 0,
    this.isExpanded = false,
    this.metadata = const {},
  });

  ${className}StateModel copyWith({
    int? activeIndex,
    bool? isExpanded,
    Map<String, dynamic>? metadata,
  }) {
    return ${className}StateModel(
      activeIndex: activeIndex ?? this.activeIndex,
      isExpanded: isExpanded ?? this.isExpanded,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ${className}Notifier extends StateNotifier<${className}StateModel> {
  ${className}Notifier() : super(const ${className}StateModel());

  void setActiveIndex(int index) => state = state.copyWith(activeIndex: index);
  void toggleExpanded() => state = state.copyWith(isExpanded: !state.isExpanded);
  void updateMetadata(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(state.metadata)..[key] = value;
    state = state.copyWith(metadata: updated);
  }
}

final ${id.replaceAll('-', '_')}Provider =
    StateNotifierProvider<${className}Notifier, ${className}StateModel>((ref) {
  return ${className}Notifier();
});
''';

    return '$modified\n$providerSnippet';
  }

  static String _adaptToGetX(String code, String id) {
    final className = _pascalCase(id);
    var modified = code;

    if (!modified.contains('package:get/get.dart')) {
      modified = "import 'package:get/get.dart';\n$modified";
    }

    final controllerSnippet = '''

class ${className}Controller extends GetxController {
  final activeIndex = 0.obs;
  final isExpanded = false.obs;
  final metadata = <String, dynamic>{}.obs;

  void setActiveIndex(int index) => activeIndex.value = index;
  void toggleExpanded() => isExpanded.value = !isExpanded.value;
  void setMetadata(String key, dynamic val) => metadata[key] = val;
}
''';

    return '$modified\n$controllerSnippet';
  }

  static String _adaptToBloc(String code, String id) {
    final className = _pascalCase(id);
    var modified = code;

    if (!modified.contains('package:flutter_bloc/flutter_bloc.dart')) {
      modified = "import 'package:flutter_bloc/flutter_bloc.dart';\n$modified";
    }

    final blocSnippet = '''

class ${className}State {
  final int activeIndex;
  final bool isExpanded;
  final Map<String, dynamic> metadata;

  const ${className}State({
    this.activeIndex = 0,
    this.isExpanded = false,
    this.metadata = const {},
  });

  ${className}State copyWith({
    int? activeIndex,
    bool? isExpanded,
    Map<String, dynamic>? metadata,
  }) {
    return ${className}State(
      activeIndex: activeIndex ?? this.activeIndex,
      isExpanded: isExpanded ?? this.isExpanded,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ${className}Cubit extends Cubit<${className}State> {
  ${className}Cubit() : super(const ${className}State());

  void setActiveIndex(int index) => emit(state.copyWith(activeIndex: index));
  void toggleExpanded() => emit(state.copyWith(isExpanded: !state.isExpanded));
  void setMetadata(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(state.metadata)..[key] = value;
    emit(state.copyWith(metadata: updated));
  }
}
''';

    return '$modified\n$blocSnippet';
  }
}

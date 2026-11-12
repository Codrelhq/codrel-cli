import '../export/component_exporter.dart';

/// Supported state management targets for `codrel add --arch`.
enum Architecture {
  /// Plain `StatefulWidget` code with no state management dependency.
  vanilla('vanilla', 'Vanilla Flutter', null),

  /// Riverpod 3 `Notifier` / `NotifierProvider` variant.
  riverpod('riverpod', 'Riverpod', 'flutter_riverpod'),

  /// GetX `GetxController` variant.
  getx('getx', 'GetX', 'get'),

  /// BLoC `Cubit` variant.
  bloc('bloc', 'BLoC', 'flutter_bloc');

  /// Value accepted by `codrel add --arch`.
  final String flag;

  /// Human-readable name.
  final String label;

  /// The pub package the generated code imports, if any.
  final String? requiredPackage;

  const Architecture(this.flag, this.label, this.requiredPackage);

  static final Map<Architecture, List<RegExp>> _forbidden = {
    Architecture.riverpod: [
      RegExp(r'\bStateNotifier\b'),
      RegExp(r'\bStateProvider\b'),
      RegExp(r'flutter_riverpod/legacy\.dart'),
      RegExp(r'\bAutoDispose\w*(Notifier|Provider)\b'),
      RegExp(r'\bFamily\w*Notifier\b|\b\w+FamilyNotifier\b'),
    ],
  };

  /// Rejects variants built on APIs that no longer compile on current
  /// versions of the target package.
  bool isUsableVariant(String code) {
    final package = requiredPackage;
    if (package != null && !code.contains('package:$package/')) return false;
    return !(_forbidden[this] ?? const []).any((r) => r.hasMatch(code));
  }

  /// Parses an `--arch` value. `normal` is accepted as an alias of
  /// [vanilla]. Throws [ArgumentError] for unsupported values.
  static Architecture parse(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'normal') return Architecture.vanilla;
    return Architecture.values.firstWhere(
      (a) => a.flag == normalized,
      orElse: () => throw ArgumentError('Unsupported architecture: $value'),
    );
  }
}

/// Produces installable source for a component.
///
/// Architecture variants are generated and verified server-side; locally the
/// adapter only guarantees the vanilla source is self-contained.
class ArchitectureAdapter {
  ArchitectureAdapter._();

  /// Returns [rawCode] as a self-contained file.
  @Deprecated('Use ComponentExporter.makeSelfContained. Architecture variants '
      'are produced by the Codrel registry.')
  static String adapt({
    required String rawCode,
    required String componentId,
    required String architecture,
  }) =>
      ComponentExporter.makeSelfContained(rawCode);
}

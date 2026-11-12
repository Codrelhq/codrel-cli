import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../adapter/architecture_adapter.dart';
import '../api/registry_client.dart';
import '../export/component_exporter.dart';
import '../models/cli_component.dart';

/// Command to download and inject a component into a Flutter project.
class AddCommand extends Command<int> {
  final RegistryClient client;

  AddCommand({required this.client}) {
    argParser
      ..addOption(
        'arch',
        abbr: 'a',
        help: 'Target state management architecture.',
        allowed: Architecture.values.map((a) => a.flag),
        defaultsTo: Architecture.vanilla.flag,
      )
      ..addOption(
        'dir',
        abbr: 'd',
        help: 'Target directory for the generated component file.',
      )
      ..addFlag(
        'overwrite',
        abbr: 'f',
        help: 'Overwrite existing file at the target destination.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help:
            'Preview the generated component code in terminal without writing to disk.',
        negatable: false,
      );
  }

  @override
  String get name => 'add';

  @override
  String get description =>
      'Download and inject an interactive micro-interaction into your Flutter project.';

  @override
  String get invocation => 'codrel add <slug> [options]';

  @override
  Future<int> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      stderr.writeln('Error: Missing component slug.');
      stderr.writeln('Usage: $invocation');
      stderr.writeln('Example: codrel add swipe-deck --arch riverpod');
      return 1;
    }

    final slug = args.first.trim().toLowerCase();
    final arch =
        Architecture.parse(argResults?['arch'] as String? ?? 'vanilla');
    final targetDirOpt = argResults?['dir'] as String?;
    final overwrite = (argResults?['overwrite'] as bool?) ?? false;
    final dryRun = (argResults?['dry-run'] as bool?) ?? false;

    if (!RegistryClient.isValidSlug(slug)) {
      stderr.writeln('Error: "$slug" is not a valid component slug.');
      stderr.writeln('Run "codrel list" to see all available components.');
      return 1;
    }

    stdout.writeln('Fetching "$slug" from the Codrel registry...');
    CliComponent? component;
    try {
      component = await client.getComponent(slug);
    } on RegistryException catch (e) {
      stderr.writeln('Error: ${e.message}');
      return 1;
    }

    if (component == null) {
      stderr.writeln(
          'Error: Component "$slug" not found in the Codrel registry.');
      stderr.writeln('Run "codrel list" to see all available components.');
      return 1;
    }

    final String code;
    try {
      code = await _resolveSource(component, arch);
    } on ExportException catch (e) {
      stderr.writeln('Error: ${e.message}');
      return 1;
    }

    if (dryRun) {
      stdout
          .writeln('\n--- [DRY RUN] ${component.fileName} (${arch.label}) ---');
      stdout.writeln(code);
      stdout.writeln('--- [END DRY RUN] ---\n');
      return 0;
    }

    final projectRoot = _findProjectRoot(Directory.current);
    final targetDir = _resolveTargetDirectory(targetDirOpt, projectRoot);
    Directory(targetDir).createSync(recursive: true);

    final targetFile = File(p.join(targetDir, component.fileName));
    if (targetFile.existsSync() && !overwrite) {
      stderr.writeln('Error: File already exists at ${targetFile.path}');
      stderr.writeln('Use --overwrite (-f) to replace the existing file.');
      return 1;
    }

    targetFile.writeAsStringSync(code);
    await client.incrementDownloads(component.id);

    stdout.writeln('\n✓ Added ${component.name}');
    stdout.writeln('   • Destination:  ${_displayPath(targetFile.path)}');
    stdout.writeln('   • Architecture: ${arch.label}');
    stdout.writeln('   • Complexity:   ${component.complexity}');

    final missingPackage = _missingDependency(projectRoot, arch);
    if (missingPackage != null) {
      stdout.writeln(
          '\n! This variant needs "$missingPackage". Install it with:');
      stdout.writeln('     flutter pub add $missingPackage');
    }

    final importLine = _importFor(targetFile.path, projectRoot);
    if (importLine != null) {
      stdout.writeln('\nImport it with:');
      stdout.writeln("   import '$importLine';");
    }
    stdout.writeln('');
    return 0;
  }

  Future<String> _resolveSource(
      CliComponent component, Architecture arch) async {
    if (arch == Architecture.vanilla) {
      return ComponentExporter.makeSelfContained(component.codeTemplate);
    }

    var variant = component.architectureTemplates[arch.flag];
    if (variant != null && !arch.isUsableVariant(variant)) variant = null;
    if (variant == null || variant.trim().isEmpty) {
      stdout.writeln('Fetching the ${arch.label} variant...');
      variant = await client.getArchitectureFromCloud(
        componentId: component.id,
        architecture: arch.flag,
      );
    }

    if (variant == null || !arch.isUsableVariant(variant)) {
      throw ExportException(
        'The ${arch.label} variant of "${component.id}" has not been published yet.\n'
        'Install the vanilla version with: codrel add ${component.id}',
      );
    }
    return ComponentExporter.makeSelfContained(variant);
  }

  String _displayPath(String path) {
    final absolute = p.normalize(p.absolute(path));
    return p.isWithin(Directory.current.path, absolute)
        ? p.relative(absolute)
        : absolute;
  }

  Directory? _findProjectRoot(Directory start) {
    var dir = start.absolute;
    while (true) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) return null;
      dir = parent;
    }
  }

  String _resolveTargetDirectory(String? userSpecified, Directory? root) {
    if (userSpecified != null && userSpecified.trim().isNotEmpty) {
      return userSpecified.trim();
    }
    final base = root?.path ?? Directory.current.path;
    for (final candidate in ['widgets', 'components']) {
      final dir = Directory(p.join(base, 'lib', candidate));
      if (dir.existsSync()) return dir.path;
    }
    return p.join(base, 'lib', 'widgets');
  }

  String? _packageName(Directory? root) {
    if (root == null) return null;
    final pubspec = File(p.join(root.path, 'pubspec.yaml')).readAsStringSync();
    return RegExp(r'^name:\s*([\w]+)', multiLine: true)
        .firstMatch(pubspec)
        ?.group(1);
  }

  String? _importFor(String filePath, Directory? root) {
    final packageName = _packageName(root);
    if (root == null || packageName == null) return null;
    final libDir = p.join(root.path, 'lib');
    final absolute = p.normalize(p.absolute(filePath));
    if (!p.isWithin(libDir, absolute)) return null;
    final relative =
        p.posix.joinAll(p.split(p.relative(absolute, from: libDir)));
    return 'package:$packageName/$relative';
  }

  String? _missingDependency(Directory? root, Architecture arch) {
    final package = arch.requiredPackage;
    if (package == null || root == null) return null;
    final pubspec = File(p.join(root.path, 'pubspec.yaml')).readAsStringSync();
    final declared = RegExp('^\\s+(flutter_riverpod|hooks_riverpod|$package):',
            multiLine: true)
        .allMatches(pubspec)
        .map((m) => m.group(1))
        .toSet();
    if (arch == Architecture.riverpod) {
      return declared.contains('flutter_riverpod') ||
              declared.contains('hooks_riverpod')
          ? null
          : package;
    }
    return declared.contains(package) ? null : package;
  }
}

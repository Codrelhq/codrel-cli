import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../adapter/architecture_adapter.dart';
import '../api/registry_client.dart';
import '../models/cli_component.dart';

/// Command to download and inject a component into a Flutter project.
class AddCommand extends Command<int> {
  final RegistryClient client;

  AddCommand({required this.client}) {
    argParser
      ..addOption(
        'arch',
        abbr: 'a',
        help:
            'Target state management architecture (vanilla, riverpod, getx, bloc).',
        allowed: ['vanilla', 'riverpod', 'getx', 'bloc'],
        defaultsTo: 'vanilla',
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
      stdout.writeln('Error: Missing component slug.');
      stdout.writeln(
          'Usage: codrel add <slug> [--arch vanilla|riverpod|getx|bloc]');
      stdout.writeln('Example: codrel add swipe-deck');
      return 1;
    }

    final slug = args.first.trim().toLowerCase();
    final arch = (argResults?['arch'] as String?) ?? 'vanilla';
    final targetDirOpt = argResults?['dir'] as String?;
    final overwrite = (argResults?['overwrite'] as bool?) ?? false;
    final dryRun = (argResults?['dry-run'] as bool?) ?? false;

    stdout.writeln('Fetching "$slug" from Codrel Registry...');
    CliComponent? component;
    try {
      component = await client.getComponent(slug);
    } on RegistryException catch (e) {
      stderr.writeln('Error: ${e.message}');
      return 1;
    }

    if (component == null) {
      stdout.writeln('Error: Component "$slug" not found in Codrel Registry.');
      stdout.writeln('Run "codrel list" to see all available components.');
      return 1;
    }

    String? adaptedCode;
    if (arch != 'vanilla' && arch != 'normal') {
      stdout.writeln('Adapting component to $arch architecture...');
      adaptedCode = await client.getArchitectureFromCloud(
        componentId: component.id,
        architecture: arch,
      );
    }

    adaptedCode ??= ArchitectureAdapter.adapt(
      rawCode: component.codeTemplate,
      componentId: component.id,
      architecture: arch,
    );

    if (dryRun) {
      stdout.writeln(
          '\n--- [DRY RUN] Generated Code (${component.fileName}) ---');
      stdout.writeln(adaptedCode);
      stdout.writeln('--- [END DRY RUN] ---\n');
      return 0;
    }

    final targetDir = _resolveTargetDirectory(targetDirOpt);
    final targetDirectory = Directory(targetDir);
    if (!targetDirectory.existsSync()) {
      targetDirectory.createSync(recursive: true);
    }

    final targetFilePath = p.join(targetDir, component.fileName);
    final targetFile = File(targetFilePath);

    if (targetFile.existsSync() && !overwrite) {
      stdout.writeln('Error: File already exists at $targetFilePath');
      stdout.writeln('Use --overwrite (-f) to replace the existing file.');
      return 1;
    }

    targetFile.writeAsStringSync(adaptedCode);

    client.incrementDownloads(component.id).ignore();

    stdout.writeln('\nSuccessfully added ${component.name}');
    stdout.writeln('   • Destination:  $targetFilePath');
    stdout.writeln('   • Architecture: $arch');
    stdout.writeln('   • Complexity:   ${component.complexity}');
    stdout.writeln('   • Tags:         ${component.tags.join(', ')}');
    stdout.writeln('\nUsage:');
    stdout.writeln('   1. Import the widget:');
    stdout.writeln('      import \'${_resolveImportPath(targetFilePath)}\';');
    stdout.writeln('   2. Add the widget to your layout tree.\n');

    return 0;
  }

  String _resolveTargetDirectory(String? userSpecified) {
    if (userSpecified != null && userSpecified.trim().isNotEmpty) {
      return userSpecified.trim();
    }

    final cwd = Directory.current.path;
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));

    if (pubspec.existsSync()) {
      final widgetsDir = Directory(p.join(cwd, 'lib', 'widgets'));
      if (widgetsDir.existsSync()) return widgetsDir.path;

      final componentsDir = Directory(p.join(cwd, 'lib', 'components'));
      if (componentsDir.existsSync()) return componentsDir.path;

      return p.join(cwd, 'lib', 'widgets');
    }

    return p.join(cwd, 'lib', 'widgets');
  }

  String _resolveImportPath(String filePath) {
    final norm = p.normalize(filePath);
    final libIndex = norm.indexOf('/lib/');
    if (libIndex != -1) {
      return norm.substring(libIndex + 5);
    }
    return p.basename(filePath);
  }
}

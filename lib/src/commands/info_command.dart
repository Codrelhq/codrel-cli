import 'dart:io';
import 'package:args/command_runner.dart';
import '../adapter/architecture_adapter.dart';
import '../api/registry_client.dart';
import '../models/cli_component.dart';

/// Command to display detailed metadata and documentation for a component.
class InfoCommand extends Command<int> {
  final RegistryClient client;

  InfoCommand({required this.client});

  @override
  String get name => 'info';

  @override
  String get description =>
      'Display detailed metadata and usage instructions for a component.';

  @override
  String get invocation => 'codrel info <slug>';

  @override
  Future<int> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      stdout.writeln('Error: Missing component slug.');
      stdout.writeln('Usage: codrel info <slug>');
      return 1;
    }

    final slug = args.first.trim().toLowerCase();
    if (!RegistryClient.isValidSlug(slug)) {
      stderr.writeln('Error: "$slug" is not a valid component slug.');
      return 1;
    }
    stdout.writeln('Looking up "$slug"...\n');

    CliComponent? component;
    try {
      component = await client.getComponent(slug);
    } on RegistryException catch (e) {
      stderr.writeln('Error: ${e.message}');
      return 1;
    }

    if (component == null) {
      stdout.writeln('Error: Component "$slug" not found in Codrel Registry.');
      return 1;
    }

    stdout.writeln(component.name);
    stdout.writeln('─' * 50);
    stdout.writeln('• Slug:         ${component.id}');
    stdout.writeln('• Complexity:   ${component.complexity}');
    stdout.writeln('• Downloads:    ${component.downloadsCount}');
    stdout.writeln('• Export File:  ${component.fileName}');
    stdout.writeln('• Tags:         ${component.tags.join(', ')}');
    stdout.writeln('\nDescription:');
    stdout.writeln('  ${component.description}');
    stdout.writeln('\nInstall commands:');
    for (final arch in Architecture.values) {
      final flag = arch == Architecture.vanilla ? '' : ' --arch ${arch.flag}';
      final cached = arch == Architecture.vanilla ||
              component.architectureTemplates.containsKey(arch.flag)
          ? ''
          : '  (not published yet)';
      stdout.writeln(
          '  • ${arch.label.padRight(16)} codrel add ${component.id}$flag$cached');
    }
    stdout.writeln('');

    return 0;
  }
}

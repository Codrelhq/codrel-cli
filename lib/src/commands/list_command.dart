import 'dart:io';
import 'package:args/command_runner.dart';
import '../api/registry_client.dart';
import '../models/cli_component.dart';

/// Command to list available interactive components in the Codrel registry.
class ListCommand extends Command<int> {
  final RegistryClient client;

  ListCommand({required this.client}) {
    argParser
      ..addOption(
        'tag',
        abbr: 't',
        help:
            'Filter components by tag (e.g. gestures, physics, cards, inputs).',
      )
      ..addOption(
        'complexity',
        abbr: 'c',
        help: 'Filter by complexity tier (Beginner, Intermediate, Advanced).',
      );
  }

  @override
  String get name => 'list';

  @override
  String get description =>
      'List all interactive components available in Codrel.';

  @override
  Future<int> run() async {
    stdout.writeln('Fetching registry components...\n');
    List<CliComponent> all;
    try {
      all = await client.listComponents();
    } on RegistryException catch (e) {
      stderr.writeln('Error: ${e.message}');
      return 1;
    }

    final tagFilter = (argResults?['tag'] as String?)?.toLowerCase().trim();
    final compFilter =
        (argResults?['complexity'] as String?)?.toLowerCase().trim();

    final filtered = all.where((c) {
      if (tagFilter != null &&
          !c.tags.any((t) => t.toLowerCase().contains(tagFilter))) {
        return false;
      }
      if (compFilter != null &&
          !c.complexity.toLowerCase().contains(compFilter)) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      stdout.writeln('No components found matching your filter criteria.');
      return 0;
    }

    stdout.writeln('Codrel Registry (${filtered.length} components):');
    stdout.writeln('─' * 76);
    stdout.writeln(
      '${'SLUG'.padRight(20)} ${'NAME'.padRight(28)} ${'COMPLEXITY'.padRight(14)} TAGS',
    );
    stdout.writeln('─' * 76);

    for (final c in filtered) {
      final tagsStr = c.tags.take(3).join(', ');
      stdout.writeln(
        '${c.id.padRight(20)} ${c.name.padRight(28)} ${c.complexity.padRight(14)} $tagsStr',
      );
    }

    stdout.writeln('─' * 76);
    stdout.writeln(
        '\nRun "codrel add <slug>" to add a component to your project.');
    stdout.writeln('Run "codrel info <slug>" to view detailed documentation.');

    return 0;
  }
}

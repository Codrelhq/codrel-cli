/// Codrel CLI library.
///
/// Provides tools to browse, fetch, and adapt interactive Flutter
/// micro-interaction components directly into client applications.
library codrel;

import 'dart:io';
import 'src/command_runner.dart';

export 'src/adapter/architecture_adapter.dart';
export 'src/api/registry_client.dart';
export 'src/command_runner.dart';
export 'src/models/cli_component.dart';

/// Entry point for running the Codrel CLI programmatically.
Future<void> main(List<String> args) async {
  final runner = CodrelCommandRunner();
  try {
    final exitCode = await runner.run(args);
    exit(exitCode ?? 0);
  } catch (error) {
    stderr.writeln('Error: $error');
    exit(1);
  } finally {
    runner.client.close();
  }
}

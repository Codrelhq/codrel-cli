/// Codrel CLI library.
///
/// Browse, fetch, and install interactive Flutter micro-interaction
/// components from the Codrel registry.
library;

import 'dart:io';
import 'package:args/command_runner.dart';
import 'src/command_runner.dart';

export 'src/adapter/architecture_adapter.dart';
export 'src/api/registry_client.dart';
export 'src/command_runner.dart';
export 'src/export/component_exporter.dart';
export 'src/models/cli_component.dart';

/// Runs the Codrel CLI with [args] and exits the process with its status.
Future<void> main(List<String> args) async {
  final runner = CodrelCommandRunner();
  var exitCode = 0;
  try {
    exitCode = await runner.run(args) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  } catch (error) {
    stderr.writeln('Error: $error');
    exitCode = 1;
  } finally {
    runner.client.close();
  }
  exit(exitCode);
}

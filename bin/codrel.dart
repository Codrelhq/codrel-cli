import 'dart:io';
import 'package:codrel/src/command_runner.dart';

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

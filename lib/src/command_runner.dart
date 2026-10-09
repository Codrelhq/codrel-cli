import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'api/registry_client.dart';
import 'commands/add_command.dart';
import 'commands/info_command.dart';
import 'commands/list_command.dart';

/// Current version of the Codrel CLI.
const String kCodrelCliVersion = '1.0.0';

/// The command runner orchestrating all Codrel CLI subcommands.
class CodrelCommandRunner extends CommandRunner<int> {
  final RegistryClient client;

  CodrelCommandRunner({RegistryClient? client})
      : client = client ?? RegistryClient(),
        super(
          'codrel',
          'Codrel CLI — Interactive Flutter Micro-Interactions Registry.',
        ) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current version of Codrel CLI.',
    );

    addCommand(AddCommand(client: this.client));
    addCommand(ListCommand(client: this.client));
    addCommand(InfoCommand(client: this.client));
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      stdout.writeln('Codrel CLI version $kCodrelCliVersion');
      return 0;
    }
    return await super.runCommand(topLevelResults) ?? 0;
  }
}

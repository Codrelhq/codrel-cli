// Command line usage:
//
//   dart pub global activate codrel
//   codrel list --tag physics
//   codrel info jelly-refresh
//   codrel add jelly-refresh --arch riverpod
//
// The same registry can be used from Dart code, for example in tooling:
import 'package:codrel/codrel.dart';

Future<void> main() async {
  final client = RegistryClient();
  try {
    final components = await client.listComponents();
    print('${components.length} components in the Codrel registry:');
    for (final component in components) {
      print('  ${component.id.padRight(20)} ${component.name}');
    }

    final component = await client.getComponent('magnetic-dock');
    if (component == null) return;

    final vanilla = ComponentExporter.makeSelfContained(component.codeTemplate);
    print('\n${component.fileName}: ${vanilla.split('\n').length} lines');

    for (final arch in Architecture.values.skip(1)) {
      final variant = component.architectureTemplates[arch.flag];
      final status = variant != null && arch.isUsableVariant(variant)
          ? 'published'
          : 'not published';
      print('  ${arch.label.padRight(8)} $status');
    }
  } on RegistryException catch (e) {
    print('Registry unavailable: ${e.message}');
  } finally {
    client.close();
  }
}

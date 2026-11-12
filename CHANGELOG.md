## 1.1.0

- **Fixed:** Installed components no longer fail to compile. Components are now exported as fully self-contained files: Codrel design tokens and context helpers are inlined as private declarations that cannot clash with your project's own `AppColors` or extensions.
- **Fixed:** `--arch riverpod` targets Riverpod 3 (`Notifier` / `NotifierProvider`). Variants built on removed APIs (`StateNotifier`, `AutoDispose*Notifier`, `*FamilyNotifier`) are rejected instead of being written to disk.
- **Changed:** Architecture variants come exclusively from the registry and are compile-verified before publication. When a variant is unavailable the CLI exits with a clear message instead of appending placeholder state classes.
- **Added:** The success message prints a correct `package:` import, and warns when the chosen architecture's package is missing from `pubspec.yaml`.
- **Added:** `codrel info` shows which architecture variants are published.
- **Added:** Project root detection walks up from the current directory, so `codrel add` works from any subfolder.
- **Security:** Component slugs are validated before being sent to the registry.
- **Deprecated:** `ArchitectureAdapter.adapt`; use `ComponentExporter.makeSelfContained`.
- **Docs:** Every public API member is documented, and a runnable `example/` shows programmatic registry access.
- **Changed:** Homepage moved to https://codrel-app.vercel.app.

## 1.0.0

- Initial release of Codrel CLI.
- `codrel add <slug>`: Inject interactive Flutter micro-interactions directly into Flutter projects.
- Multi-architecture code generation engine with support for `--arch vanilla`, `--arch riverpod`, `--arch getx`, and `--arch bloc`.
- `codrel list`: Search, filter, and inspect components by tags and complexity tiers.
- `codrel info <slug>`: Display comprehensive component metadata, parameters, and usage instructions.
- Smart project detection: Automatically detects project structure and locates `lib/widgets` directory.

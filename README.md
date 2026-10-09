# Codrel CLI

[![pub package](https://img.shields.io/pub/v/codrel.svg)](https://pub.dev/packages/codrel)
[![Dart SDK](https://img.shields.io/badge/dart-3.0%2B-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

The official command-line interface for **[Codrel](https://codrel.dev)** — the curated Flutter micro-interactions registry.

Codrel enables Flutter developers to discover, preview, and inject production-grade interactive widgets and animations directly into their codebases with a single command. Every component is fully customizable, self-contained, and automatically adapts to your preferred state management architecture.

---

## ⚡ Features

- **Direct Injection**: Add interactive widgets directly into your project directory — no bloated runtime dependencies.
- **Multi-Architecture Adaptation**: Generate components pre-configured for Vanilla Flutter, Riverpod, GetX, or BLoC.
- **Production-Ready**: Fluid 60fps animations, physics gestures, haptics, and responsive layout constraints.
- **Material 3 Adaptive**: Components dynamically adapt to your application's light and dark color schemes.
- **Smart Directory Detection**: Automatically detects your Flutter project structure and places components in your widgets directory.

---

## 🚀 Getting Started

### Global Installation (Recommended)

Activate the CLI globally to run `codrel` anywhere on your machine:

```bash
dart pub global activate codrel
```

Verify the installation:

```bash
codrel --version
```

### Per-Project Installation

Alternatively, add `codrel` to your project's `dev_dependencies`:

```yaml
dev_dependencies:
  codrel: ^1.0.0
```

Then invoke commands via:

```bash
dart run codrel <command>
```

---

## 📖 Command Reference

### `codrel add <slug>`

Downloads and injects a component into your Flutter project.

```bash
# Add a component using standard Flutter (StatefulWidget)
codrel add swipe-deck

# Adapt for Riverpod (ConsumerStatefulWidget + StateNotifierProvider)
codrel add swipe-deck --arch riverpod

# Adapt for GetX (GetxController + reactive state)
codrel add swipe-deck --arch getx

# Adapt for BLoC (Cubit + state model)
codrel add swipe-deck --arch bloc
```

#### Options

| Option        | Flag | Description                                                        | Default       |
| :------------ | :--- | :----------------------------------------------------------------- | :------------ |
| `--arch`      | `-a` | State management pattern (`vanilla`, `riverpod`, `getx`, `bloc`)   | `vanilla`     |
| `--dir`       | `-d` | Destination directory for the generated file                       | `lib/widgets` |
| `--overwrite` | `-f` | Overwrite existing file at destination                             | `false`       |
| `--dry-run`   |      | Preview the generated Dart source code in terminal without writing | `false`       |

---

### `codrel list`

Browse all components available in the Codrel registry.

```bash
# List all components
codrel list

# Filter by category tag
codrel list --tag gestures
codrel list --tag auth
codrel list --tag inputs

# Filter by complexity level
codrel list --complexity Beginner
codrel list --complexity Intermediate
codrel list --complexity Advanced
```

---

### `codrel info <slug>`

Inspect detailed metadata, tags, difficulty, and usage commands for any component.

```bash
codrel info dynamic-island
codrel info smart-otp
codrel info swipe-deck
```

---

## 🏛 Supported Architectures

Codrel eliminates the friction of manually refactoring third-party widgets into your team's architectural conventions:

| Architecture | Flag              | Output Structure                                                                                             |
| :----------- | :---------------- | :----------------------------------------------------------------------------------------------------------- |
| **Vanilla**  | `--arch vanilla`  | Standard Flutter `StatefulWidget` or `StatelessWidget`. Zero external state dependencies.                    |
| **Riverpod** | `--arch riverpod` | Converts to `ConsumerStatefulWidget` and provides a dedicated `StateNotifierProvider` managing widget state. |
| **GetX**     | `--arch getx`     | Generates a companion `GetxController` with observable reactive properties (`.obs`).                         |
| **BLoC**     | `--arch bloc`     | Generates an immutable state model and corresponding `Cubit` for state emissions.                            |

---

## 📦 Component Registry Highlights

A selection of micro-interactions available in the registry:

| Slug              | Component                 | Complexity   | Highlights                                                                    |
| :---------------- | :------------------------ | :----------- | :---------------------------------------------------------------------------- |
| `swipe-deck`      | Swipe Card Deck           | Intermediate | Tinder-style velocity physics, tilt rotation, dynamic like/pass stamps.       |
| `smart-otp`       | Smart OTP & PIN Input     | Intermediate | Smooth auto-focus progression, paste interception, animated cursor indicator. |
| `dynamic-island`  | Dynamic Island HUD        | Advanced     | Expandable pill notification header with morphing springs and physics.        |
| `neu-button`      | Neumorphic Action Button  | Beginner     | Soft inset shadows, haptic feedback triggers, and smooth elevation dip.       |
| `shimmer-card`    | Shimmer Skeleton Card     | Beginner     | High-performance linear gradient shimmer placeholder for content loading.     |
| `liquid-progress` | Liquid Progress Indicator | Intermediate | Wave-sine animation with fluid volume filling effect.                         |
| `pull-refresh`    | Elastic Pull-to-Refresh   | Intermediate | Rubber-band overscroll resistance with custom geometric spinner.              |

---

## 🛠 Customizing Injected Code

Codrel follows the philosophy that **you own the code**. Injected components are placed directly into your codebase without external black-box library abstractions, allowing you to:

1. Modify colors, curves, and animation durations to match your brand design system.
2. Extend callbacks, controllers, and models to bind with your backend APIs.
3. Keep your application bundle lightweight and free of unnecessary dependencies.

---

## 🤝 Contributing

Contributions to the Codrel registry and CLI are welcome! If you have built an interactive Flutter micro-interaction or want to report an issue:

- Issues & Feature Requests: [GitHub Issues](https://github.com/Codrelhq/codrel-cli/issues)
- Source Repository: [GitHub Repository](https://github.com/Codrelhq/codrel-cli)
- Web Platform: [codrel.dev](https://codrel.dev)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

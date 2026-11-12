# Codrel CLI

[![pub package](https://img.shields.io/pub/v/codrel.svg)](https://pub.dev/packages/codrel)
[![Dart SDK](https://img.shields.io/badge/dart-3.0%2B-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

The official command-line interface for **[Codrel](https://codrel-app.vercel.app)** — the curated Flutter micro-interactions registry.

Codrel enables Flutter developers to discover, preview, and inject production-grade interactive widgets and animations directly into their codebases with a single command. Every component is fully customizable, self-contained, and automatically adapts to your preferred state management architecture.

---

## ⚡ Features

- **Direct Injection**: Add interactive widgets directly into your project directory — no bloated runtime dependencies.
- **Multi-Architecture Adaptation**: Generate components pre-configured for Vanilla Flutter, Riverpod, GetX, or BLoC.
- **Compiles on install**: Every component is verified to compile standalone before it is published to the registry.
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
  codrel: ^1.1.0
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

# Riverpod 3 variant (Notifier + NotifierProvider)
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

# Filter by tag
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

Every component ships as a single, self-contained Dart file — no Codrel runtime, no extra dependencies for the vanilla version.

| Architecture | Flag              | Output                                                                                       | Requires           |
| :----------- | :---------------- | :------------------------------------------------------------------------------------------- | :----------------- |
| **Vanilla**  | _(default)_       | Standard Flutter `StatefulWidget`, zero dependencies.                                        | —                  |
| **Riverpod** | `--arch riverpod` | Widget state moved into a Riverpod 3 `Notifier` + `NotifierProvider`, consumed via `ConsumerStatefulWidget`. | `flutter_riverpod` |
| **GetX**     | `--arch getx`     | State moved into a `GetxController` with reactive `.obs` fields bound through `Obx`.         | `get`              |
| **BLoC**     | `--arch bloc`     | State moved into a `Cubit` with an immutable state class, bound through `BlocBuilder`.       | `flutter_bloc`     |

Architecture variants are generated from the vanilla source and only published to the registry after they pass a compile check against the current versions of `flutter_riverpod`, `get`, and `flutter_bloc`. If a variant has not been published yet, the CLI tells you instead of writing code, and the vanilla version is always available.

---

## 📦 Component Registry

| Slug                | Component                  | Complexity   |
| :------------------ | :------------------------- | :----------- |
| `swipe-deck`        | Swipe Card Deck            | Intermediate |
| `crypto-chart`      | Interactive Price Chart    | Advanced     |
| `bottom-sheet`      | Dynamic Multi-Snap Sheet   | Intermediate |
| `smart-otp`         | Smart OTP & PIN Input      | Intermediate |
| `morphing-cta`      | Morphing Checkout CTA      | Intermediate |
| `dynamic-island`    | Dynamic Island Pill        | Advanced     |
| `card-flip-3d`      | 3D Gyro Credit Card        | Advanced     |
| `tactile-slider`    | Tactile Scrub Slider       | Intermediate |
| `radial-menu`       | Radial Arc Menu            | Intermediate |
| `reaction-bar`      | Interactive Reaction Bar   | Intermediate |
| `swipe-action-tile` | Swipeable Action Tile      | Intermediate |
| `liquid-tabs`       | Liquid Tab Indicator       | Intermediate |
| `skeleton-shimmer`  | Wave Shimmer Skeleton      | Beginner     |
| `magnetic-switch`   | Magnetic Day/Night Switch  | Beginner     |
| `confetti-burst`    | Celebration Confetti Burst | Intermediate |
| `dissolve-delete`   | Dissolve Delete            | Advanced     |
| `jelly-refresh`     | Jelly Pull-to-Refresh      | Advanced     |
| `magnetic-dock`     | Magnetic Dock              | Intermediate |
| `scratch-reveal`    | Scratch-to-Reveal Card     | Intermediate |

Run `codrel list` for the live catalog.

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
- Web Platform: [codrel-app.vercel.app](https://codrel-app.vercel.app)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

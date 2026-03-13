# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Lint / static analysis
flutter analyze

# Build
flutter build apk       # Android
flutter build ios       # iOS
flutter build web       # Web
```

## Architecture

This is a Flutter (Dart) cross-platform app targeting Android, iOS, web, macOS, Windows, and Linux.

- `lib/` — all Dart source code; `lib/main.dart` is the entry point
- `test/` — widget and unit tests using `flutter_test`
- `analysis_options.yaml` — linter config (uses `flutter_lints` recommended rules)
- Platform folders (`android/`, `ios/`, `web/`, etc.) contain platform-specific scaffolding

State management currently uses Flutter's built-in `setState`. As the app grows, prefer scoping state with `StatefulWidget` or introduce a dedicated state management solution (e.g., `riverpod`, `bloc`) rather than lifting state into `main.dart`.

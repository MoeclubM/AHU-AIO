# AHU AIO

A Flutter application that aggregates Anhui University academic services such as timetables, course selection, notices, and classroom reservations in a single mobile experience.

## Prerequisites

To build or test the project locally (and to match the configuration used in CI) install the following tooling:

- [Flutter SDK 3.35.7](https://docs.flutter.dev/get-started/install) (ships with Dart 3.9.x)
- A recent Android Studio or Visual Studio Code installation if you plan to run the application on a device or emulator
- Platform-specific SDKs as required by your target platform (Android SDK, iOS toolchain, etc.)

## First-time setup

```bash
# Fetch dependencies
flutter pub get

# Optional: clean any previous build outputs
flutter clean
```

The repository does not vendor the Flutter SDK. When developing inside a container or CI system, download the SDK and add `<flutter-sdk>/bin` to the `PATH` before running any Flutter commands. GitHub Actions now installs Flutter 3.35.7 and Dart 3.9.2, so the `pubspec.yaml` tracks the latest compatible package releases (WebView 4.13.x, Flutter SVG 2.2.x, Provider 6.1.5+1, etc.) and resolves cleanly without manual overrides.

## Quality checks

The project relies on Flutter's built-in tooling for static analysis and tests. Run the following commands before submitting changes so they match what GitHub Actions executes:

```bash
# Lint the Dart and Flutter sources
flutter analyze

# Execute the widget and service tests
flutter test
```

Both commands must succeed for the build to pass in CI. The added schedule service tests ensure the timetable correctly filters courses by week, highlights the active teaching week, and marks honor courses.

## Running the app

Use Flutter's standard device tooling to launch the app on an emulator or a connected device:

```bash
flutter run
```

When verifying the course schedule module, use the provided student account (`P124301206`, password `Yao060723@`) to confirm current-week filtering and honor-course indicators in the simplified native UI.

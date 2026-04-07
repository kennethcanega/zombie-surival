# Zombie Survival MVP (Flutter + Flame)

A beginner-friendly 2D top-down survival zombie game MVP targeting Android first.

## Prerequisites

- Flutter SDK (stable channel)
- Android Studio (or Android SDK + platform tools)
- An Android emulator or physical Android device with USB debugging enabled

## Get started

1. Install dependencies:

```bash
flutter pub get
```

2. Run on Android:

```bash
flutter run -d android
```

If you have multiple devices attached, check available devices first:

```bash
flutter devices
```

Then run with a specific device id:

```bash
flutter run -d <device-id>
```

## Build release APK

```bash
flutter build apk --release
```

APK output path:

- `build/app/outputs/flutter-apk/app-release.apk`

## Project structure (MVP)

- `lib/main.dart`: app bootstrap and Flame `GameWidget` overlays
- `lib/game/zombie_survival_game.dart`: core game loop/state
- `lib/game/components/`: player and zombie components
- `lib/game/systems/`: attack/day/upgrade systems
- `lib/game/ui/`: HUD, level-up, and game-over overlays

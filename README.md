# 🐦 Flappy Dash

A Flappy Bird–style tap game built with **Flutter** and the **Flame** game engine.
Tap the screen to make the bird flap, fly through the gaps between the pipes,
and try to beat your high score!

<p align="center">
  <em>Tap to flap · Avoid the pipes · Beat your best score</em>
</p>

## 🎮 Gameplay

- **Tap anywhere** to make the bird flap upward.
- Gravity constantly pulls the bird down.
- Fly through the gap between each pair of pipes to score a point.
- Touching a pipe or the ground ends the game.
- Your best score is remembered during the session.

## 📱 Download & install the APK (no tools needed)

This repo builds an installable Android `.apk` automatically using GitHub Actions.

1. Go to the **[Actions](../../actions)** tab of this repository.
2. Open the most recent **"Build Android APK"** run (green ✓).
3. Scroll down to the **Artifacts** section and download **`flappy-dash-release-apk`**.
4. Unzip it — inside you'll find `app-release.apk`.
5. Copy the `.apk` to your Android phone and open it to install.
   - You may need to allow **"Install from unknown sources"** in your phone settings.

> 💡 **Tip:** You can also trigger a build manually from the Actions tab via
> **"Run workflow"**, or create a release by pushing a tag like `v1.0.0` — the
> APK will be attached to the GitHub Release automatically.

## 🛠️ Build it yourself (optional)

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.5+)
and the Android toolchain.

```bash
# Get dependencies
flutter pub get

# Run on a connected device / emulator
flutter run

# Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

You can also play it in a browser:

```bash
flutter run -d chrome
```

## 🧱 Project structure

```
lib/
├── main.dart                  # App entry point + menu / game-over overlays
├── game/
│   └── flappy_game.dart        # Core game loop, state, scoring, pipe spawning
└── components/
    ├── background.dart         # Sky gradient + clouds
    ├── ground.dart             # Scrolling ground
    ├── bird.dart               # Player bird (physics, drawing, collisions)
    ├── pipe_pair.dart          # Obstacle pipes + scoring trigger
    └── score_text.dart         # On-screen score display
```

## ⚙️ Tech stack

- [Flutter](https://flutter.dev/) — UI toolkit
- [Flame](https://flame-engine.org/) `1.18.0` — 2D game engine
- GitHub Actions — automatic APK builds

## 📄 License

Free to use and modify for learning and fun.

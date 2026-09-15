# 🐦 Flappy Vappstore

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

## ✨ Features

- 🪙 **Coins** — collect coins in the gaps and spend them in the shop.
- 🎨 **Bird shop** — 6 bird skins; the first is free, the rest unlock with coins.
- 🖼️ **Themes** — 4 swappable pipe + sky colour schemes (Classic, Sunset, Candy, Ocean).
- ⚡ **Power-ups** (5 types):
  - 🛡️ **Shield** — absorbs one pipe hit.
  - ⏱️ **Slow-mo** — slows the world down.
  - 🧲 **Magnet** — pulls nearby coins toward you.
  - 🔽 **Mini** — shrinks the bird so tight gaps are easier.
  - ✖️2 **Double score** — points count double.
- 🔥 **Combo system** — chain pipes without breaking your streak to raise a score multiplier.
- 👆 **Tap-to-start** — the bird hovers until your first tap.
- 🏆 **Achievements** with coin rewards + a **daily mission**.
- 📊 **Player stats** — games, pipes, coins, best combo, total flight time.
- 💥 **Particle & pop-up effects** — coin sparkles, crash burst, combo/power-up text.
- 🔊 **Sound effects** + 🎵 **background music**, each with a toggle.
- ⚙️ **Settings menu** (SFX / music / vibration) plus quick links to stats & awards.
- 📈 **Progressive difficulty** — faster and narrower as your score climbs.
- 💾 **Persistent** high score, coins, skins, stats and settings.
- 🏆 **Local leaderboard** (top 5) with your player name.
- 📤 **Share your score** via the system share sheet.
- 🏠 **Home button** on the pause and game-over screens.
- 🌗 **Day → night** sky that darkens with difficulty.
- 🏅 **Medals**: Bronze, Silver, Gold, Platinum.
- 📳 **Haptic feedback** on crash and power-up pickup.

> 🔑 **Signed releases:** the APK is signed with a persistent release key when the
> repo's signing secrets are configured, so updates install over previous
> versions without uninstalling.

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
├── main.dart                  # App entry + all overlays (menu, HUD, pause, game over, dialogs)
├── game/
│   ├── flappy_game.dart        # Core loop: state, scoring, combo, power-ups, difficulty
│   ├── bird_skins.dart         # Bird colour schemes
│   └── themes.dart             # Pipe + sky themes
├── components/
│   ├── background.dart         # Day/night sky (themed) + clouds/stars/moon
│   ├── ground.dart             # Scrolling ground
│   ├── bird.dart               # Player bird (physics, skins, mini, shield, collisions)
│   ├── pipe_pair.dart          # Obstacle pipes (themed) + scoring trigger
│   ├── coin.dart               # Collectible coins (magnet-aware)
│   ├── power_up.dart           # 5 power-up types
│   ├── effects.dart            # Particle bursts + floating text
│   └── score_text.dart         # On-screen score display
└── services/
    ├── game_storage.dart       # Persistence: coins, skins, stats, achievements, mission
    └── audio_manager.dart      # SFX + background music
assets/
├── audio/                      # flap / score / hit / music
└── icon/                       # app launcher icon source
```

## ⚙️ Tech stack

- [Flutter](https://flutter.dev/) — UI toolkit
- [Flame](https://flame-engine.org/) `1.18.0` — 2D game engine
- [audioplayers](https://pub.dev/packages/audioplayers) — sound effects
- [shared_preferences](https://pub.dev/packages/shared_preferences) — persistent high score
- GitHub Actions — automatic APK builds

## 📄 License

Free to use and modify for learning and fun. 

by Indonesia V-AppStore Team

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/flappy_game.dart';
import 'services/audio_manager.dart';
import 'services/game_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameStorage.instance.load();
  await AudioManager.instance.init();
  runApp(const FlappyApp());
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Vappstore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = FlappyGame();
    return Scaffold(
      body: GameWidget<FlappyGame>(
        game: game,
        overlayBuilderMap: {
          'menu': (context, g) => MenuOverlay(game: g),
          'hud': (context, g) => HudOverlay(game: g),
          'paused': (context, g) => PausedOverlay(game: g),
          'gameOver': (context, g) => GameOverOverlay(game: g),
        },
        initialActiveOverlays: const ['menu'],
      ),
    );
  }
}

/// Reusable game button.
class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 22)),
    );
  }
}

/// Overlay shown before the game starts.
class MenuOverlay extends StatefulWidget {
  const MenuOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Flappy',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            const Text(
              'Vappstore',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.amber,
                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap anywhere to flap',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${widget.game.highScore}',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 28),
            _GameButton(label: 'PLAY', onPressed: widget.game.startGame),
            const SizedBox(height: 12),
            _SoundToggleButton(onChanged: () => setState(() {})),
          ],
        ),
      ),
    );
  }
}

/// Small button to toggle sound on/off, persisted via GameStorage.
class _SoundToggleButton extends StatelessWidget {
  const _SoundToggleButton({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = GameStorage.instance.soundEnabled;
    return TextButton.icon(
      onPressed: () async {
        await GameStorage.instance.setSoundEnabled(!enabled);
        onChanged();
      },
      icon: Icon(
        enabled ? Icons.volume_up : Icons.volume_off,
        color: Colors.white,
      ),
      label: Text(
        enabled ? 'Sound: ON' : 'Sound: OFF',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

/// In-game heads-up display: pause + sound buttons in the top corners.
class HudOverlay extends StatefulWidget {
  const HudOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircleIconButton(
              icon: Icons.pause,
              onPressed: widget.game.pauseGame,
            ),
            _CircleIconButton(
              icon: GameStorage.instance.soundEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
              onPressed: () async {
                await GameStorage.instance
                    .setSoundEnabled(!GameStorage.instance.soundEnabled);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/// Overlay shown when the game is paused.
class PausedOverlay extends StatelessWidget {
  const PausedOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _GameButton(label: 'RESUME', onPressed: game.resumeGame),
          ],
        ),
      ),
    );
  }
}

/// Overlay shown when the player loses.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    final medal = Medal.forScore(game.score);
    return Container(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 16),
            if (medal.name.isNotEmpty) ...[
              Icon(Icons.military_tech, color: medal.color, size: 64),
              Text(
                medal.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: medal.color,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Score: ${game.score}',
              style: const TextStyle(fontSize: 26, color: Colors.white),
            ),
            Text(
              'Best: ${game.highScore}',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            if (game.isNewHighScore) ...[
              const SizedBox(height: 6),
              const Text(
                '🎉 New Best!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _GameButton(label: 'RETRY', onPressed: game.startGame),
          ],
        ),
      ),
    );
  }
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/flappy_game.dart';

void main() {
  runApp(const FlappyApp());
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Dash',
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
          'gameOver': (context, g) => GameOverOverlay(game: g),
        },
        initialActiveOverlays: const ['menu'],
      ),
    );
  }
}

/// Overlay shown before the game starts.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Flappy Dash',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap anywhere to flap',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: game.startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('PLAY', style: TextStyle(fontSize: 24)),
            ),
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
            const SizedBox(height: 12),
            Text(
              'Score: ${game.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            Text(
              'Best: ${game.highScore}',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: game.startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('RETRY', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}

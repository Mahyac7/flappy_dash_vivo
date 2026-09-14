import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/background.dart';
import '../components/bird.dart';
import '../components/ground.dart';
import '../components/pipe_pair.dart';
import '../components/score_text.dart';

/// Possible states the game can be in.
enum GameState { menu, playing, gameOver }

/// Core game class for Flappy Dash.
///
/// Handles gravity, spawning pipes, scoring, collisions and state changes.
class FlappyGame extends FlameGame with TapDetector, HasCollisionDetection {
  FlappyGame();

  // --- Tuning constants ---
  /// Downward acceleration applied to the bird (pixels / second^2).
  static const double gravity = 1600;

  /// Upward velocity applied when the player taps (pixels / second).
  static const double flapVelocity = -480;

  /// Horizontal speed everything moves left at (pixels / second).
  static const double worldSpeed = 160;

  /// Vertical gap between the top and bottom pipe.
  static const double pipeGap = 220;

  /// Time between spawning new pipe pairs (seconds).
  static const double pipeInterval = 1.6;

  final Random _random = Random();

  late Bird bird;
  late ScoreText _scoreText;

  GameState state = GameState.menu;
  int score = 0;
  int highScore = 0;

  double _pipeTimer = 0;

  @override
  Color backgroundColor() => const Color(0xFF4EC0CA);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Parallax-ish static background + moving ground.
    add(Background());
    add(Ground());

    bird = Bird();
    add(bird);

    _scoreText = ScoreText();
    add(_scoreText);
  }

  /// Starts (or restarts) a game round.
  void startGame() {
    overlays.remove('menu');
    overlays.remove('gameOver');

    // Remove any leftover pipes from the previous round.
    children.whereType<PipePair>().toList().forEach(remove);

    score = 0;
    _pipeTimer = 0;
    _scoreText.updateScore(0);
    bird.reset();
    state = GameState.playing;
  }

  /// Called by a pipe when the bird successfully passes it.
  void increaseScore() {
    score++;
    _scoreText.updateScore(score);
  }

  /// Ends the current round and shows the game-over overlay.
  void gameOver() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    if (score > highScore) highScore = score;
    bird.die();
    overlays.add('gameOver');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;

    _pipeTimer += dt;
    if (_pipeTimer >= pipeInterval) {
      _pipeTimer = 0;
      _spawnPipe();
    }
  }

  void _spawnPipe() {
    // Keep the gap comfortably away from the very top and the ground.
    const double topMargin = 80;
    final double groundTop = size.y - Ground.groundHeight;
    const double minCenter = topMargin + pipeGap / 2;
    final double maxCenter = groundTop - pipeGap / 2 - 40;
    final double gapCenter =
        minCenter + _random.nextDouble() * (maxCenter - minCenter);

    add(PipePair(gapCenter: gapCenter));
  }

  @override
  void onTap() {
    switch (state) {
      case GameState.playing:
        bird.flap();
        break;
      case GameState.menu:
      case GameState.gameOver:
        // Overlays handle their own buttons; ignore taps on the raw canvas.
        break;
    }
  }
}

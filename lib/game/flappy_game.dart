import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

import '../components/background.dart';
import '../components/bird.dart';
import '../components/ground.dart';
import '../components/pipe_pair.dart';
import '../components/power_up.dart';
import '../components/score_text.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';

/// Possible states the game can be in.
enum GameState { menu, playing, paused, gameOver }

/// Core game class for Flappy Vappstore.
///
/// Handles gravity, spawning pipes, scoring, collisions, progressive
/// difficulty, day/night transition, power-ups, sound and state changes.
class FlappyGame extends FlameGame with TapDetector, HasCollisionDetection {
  FlappyGame();

  // --- Tuning constants ---
  /// Downward acceleration applied to the bird (pixels / second^2).
  static const double gravity = 1600;

  /// Upward velocity applied when the player taps (pixels / second).
  static const double flapVelocity = -480;

  /// Base horizontal speed at score 0 (pixels / second).
  static const double baseWorldSpeed = 160;

  /// Maximum horizontal speed the game ramps up to.
  static const double maxWorldSpeed = 320;

  /// Vertical gap between pipes at score 0.
  static const double basePipeGap = 230;

  /// Smallest the gap is ever allowed to shrink to.
  static const double minPipeGap = 150;

  /// Score at which difficulty reaches its hardest setting.
  static const double difficultyRampScore = 30;

  // Power-up tuning.
  static const double shieldDuration = 6.0;
  static const double slowMoDuration = 5.0;
  static const double slowMoFactor = 0.55;

  final Random _random = Random();

  late Bird bird;
  late ScoreText _scoreText;
  late Background background;

  GameState state = GameState.menu;
  int score = 0;
  int highScore = 0;
  bool isNewHighScore = false;
  bool madeLeaderboard = false;

  double _pipeTimer = 0;
  int _pipesSincePowerUp = 0;

  /// Remaining slow-motion time in seconds (0 = normal speed).
  double slowMoTime = 0;
  bool get isSlowMo => slowMoTime > 0;

  /// Multiplier applied to horizontal movement (for slow-mo).
  double get timeScale => isSlowMo ? slowMoFactor : 1.0;

  /// 0.0 (easy) .. 1.0 (hardest), derived from the current score.
  double get difficulty =>
      (score / difficultyRampScore).clamp(0.0, 1.0).toDouble();

  /// Current world speed, scaled by difficulty and slow-mo.
  double get worldSpeed =>
      (baseWorldSpeed + (maxWorldSpeed - baseWorldSpeed) * difficulty) *
      timeScale;

  /// Current pipe gap, shrinking with difficulty.
  double get pipeGap => basePipeGap - (basePipeGap - minPipeGap) * difficulty;

  /// Seconds between pipe spawns, shortening slightly with difficulty.
  double get pipeInterval => (1.7 - 0.5 * difficulty) / timeScale;

  @override
  Color backgroundColor() => const Color(0xFF4EC0CA);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    highScore = GameStorage.instance.highScore;

    background = Background();
    add(background);
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
    overlays.remove('hud');

    // Remove leftover pipes and power-ups from the previous round.
    children.whereType<PipePair>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);

    score = 0;
    _pipeTimer = 0;
    _pipesSincePowerUp = 0;
    slowMoTime = 0;
    isNewHighScore = false;
    madeLeaderboard = false;
    _scoreText.updateScore(0);
    bird.reset();
    state = GameState.playing;
    overlays.add('hud');

    AudioManager.instance.startMusic();
  }

  /// Returns to the main menu.
  void goHome() {
    children.whereType<PipePair>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);
    overlays.remove('paused');
    overlays.remove('gameOver');
    overlays.remove('hud');
    slowMoTime = 0;
    state = GameState.menu;
    bird.reset();
    AudioManager.instance.pauseMusic();
    overlays.add('menu');
  }

  /// Pauses gameplay.
  void pauseGame() {
    if (state != GameState.playing) return;
    state = GameState.paused;
    AudioManager.instance.pauseMusic();
    overlays.add('paused');
  }

  /// Resumes from pause.
  void resumeGame() {
    if (state != GameState.paused) return;
    overlays.remove('paused');
    state = GameState.playing;
    AudioManager.instance.startMusic();
  }

  /// Called by a pipe when the bird successfully passes it.
  void increaseScore() {
    score++;
    _scoreText.updateScore(score);
    AudioManager.instance.playScore();
  }

  /// Called when the shield absorbs a hit instead of the bird dying.
  void onShieldConsumed() {
    HapticFeedback.lightImpact();
    AudioManager.instance.playHit();
  }

  /// Applies a collected power-up.
  void collectPowerUp(PowerUpType type) {
    AudioManager.instance.playPowerUp();
    HapticFeedback.selectionClick();
    switch (type) {
      case PowerUpType.shield:
        bird.grantShield(shieldDuration);
        break;
      case PowerUpType.slowMo:
        slowMoTime = max(slowMoTime, slowMoDuration);
        break;
    }
  }

  /// Ends the current round and shows the game-over overlay.
  Future<void> gameOver() async {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    bird.die();

    AudioManager.instance.playHit();
    AudioManager.instance.pauseMusic();
    HapticFeedback.mediumImpact();

    isNewHighScore = await GameStorage.instance.maybeSaveHighScore(score);
    madeLeaderboard = await GameStorage.instance.addScore(score);
    highScore = GameStorage.instance.highScore;

    overlays.remove('hud');
    overlays.remove('paused');
    overlays.add('gameOver');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;

    if (slowMoTime > 0) {
      slowMoTime -= dt;
    }

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
    final double gap = pipeGap;
    final double minCenter = topMargin + gap / 2;
    final double maxCenter = groundTop - gap / 2 - 40;
    final double gapCenter =
        minCenter + _random.nextDouble() * (maxCenter - minCenter);

    add(PipePair(gapCenter: gapCenter, gap: gap));

    // Occasionally spawn a power-up in a gap (roughly every 4-6 pipes).
    _pipesSincePowerUp++;
    if (_pipesSincePowerUp >= 4 && _random.nextDouble() < 0.5) {
      _pipesSincePowerUp = 0;
      final type =
          _random.nextBool() ? PowerUpType.shield : PowerUpType.slowMo;
      add(PowerUp(
        type: type,
        position: Vector2(size.x + 160, gapCenter),
      ));
    }
  }

  @override
  void onTap() {
    switch (state) {
      case GameState.playing:
        bird.flap();
        AudioManager.instance.playFlap();
        break;
      case GameState.menu:
      case GameState.paused:
      case GameState.gameOver:
        // Overlays / buttons handle these states.
        break;
    }
  }
}

/// Returns a medal label + color for a given score.
class Medal {
  const Medal(this.name, this.color);
  final String name;
  final Color color;

  static Medal forScore(int score) {
    if (score >= 40) return const Medal('PLATINUM', Color(0xFFE5E4E2));
    if (score >= 25) return const Medal('GOLD', Color(0xFFFFD700));
    if (score >= 12) return const Medal('SILVER', Color(0xFFC0C0C0));
    if (score >= 5) return const Medal('BRONZE', Color(0xFFCD7F32));
    return const Medal('', Color(0x00000000));
  }
}

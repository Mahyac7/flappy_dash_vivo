import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

import '../components/background.dart';
import '../components/bird.dart';
import '../components/coin.dart';
import '../components/effects.dart';
import '../components/ground.dart';
import '../components/pipe_pair.dart';
import '../components/power_up.dart';
import '../components/score_text.dart';
import '../services/audio_manager.dart';
import '../services/game_storage.dart';

/// Possible states the game can be in.
///
/// [ready] = tap-to-start: the bird hovers, gravity is off until the first tap.
enum GameState { menu, ready, playing, paused, gameOver }

/// Core game class for Flappy Vappstore.
class FlappyGame extends FlameGame with TapDetector, HasCollisionDetection {
  FlappyGame();

  // --- Tuning constants ---
  static const double gravity = 1600;
  static const double flapVelocity = -480;
  static const double baseWorldSpeed = 160;
  static const double maxWorldSpeed = 320;
  static const double basePipeGap = 230;
  static const double minPipeGap = 150;
  static const double difficultyRampScore = 30;

  // Power-up tuning.
  static const double shieldDuration = 6.0;
  static const double slowMoDuration = 5.0;
  static const double slowMoFactor = 0.55;
  static const double magnetDuration = 7.0;
  static const double miniDuration = 7.0;
  static const double doubleScoreDuration = 8.0;

  // Combo tuning: consecutive pipes raise a multiplier.
  static const int comboStep = 5; // every N pipes → +1 multiplier

  final Random _random = Random();

  late Bird bird;
  late ScoreText _scoreText;
  late Background background;

  GameState state = GameState.menu;
  int score = 0;
  int highScore = 0;
  bool isNewHighScore = false;
  bool madeLeaderboard = false;

  // Run-scoped counters.
  int coinsThisRun = 0;
  int pipesThisRun = 0;
  int combo = 0;
  int bestComboThisRun = 0;
  double _flightSeconds = 0;
  List<Achievement> newlyUnlocked = [];

  double _pipeTimer = 0;
  int _pipesSincePowerUp = 0;

  // Power-up timers.
  double slowMoTime = 0;
  double magnetTime = 0;
  double miniTime = 0;
  double doubleScoreTime = 0;

  bool get isSlowMo => slowMoTime > 0;
  bool get isMagnet => magnetTime > 0;
  bool get isMini => miniTime > 0;
  bool get isDoubleScore => doubleScoreTime > 0;

  double get timeScale => isSlowMo ? slowMoFactor : 1.0;

  /// Current combo multiplier (1x, 2x, 3x ...).
  int get comboMultiplier => 1 + (combo ~/ comboStep);

  double get difficulty =>
      (score / difficultyRampScore).clamp(0.0, 1.0).toDouble();

  double get worldSpeed =>
      (baseWorldSpeed + (maxWorldSpeed - baseWorldSpeed) * difficulty) *
      timeScale;

  double get pipeGap => basePipeGap - (basePipeGap - minPipeGap) * difficulty;

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

  void _clearRunComponents() {
    children.whereType<PipePair>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);
    children.whereType<Coin>().toList().forEach(remove);
  }

  void _resetTimers() {
    slowMoTime = 0;
    magnetTime = 0;
    miniTime = 0;
    doubleScoreTime = 0;
  }

  /// Enters the "ready" (tap-to-start) state where the bird hovers.
  void startGame() {
    overlays.remove('menu');
    overlays.remove('gameOver');
    _clearRunComponents();

    score = 0;
    coinsThisRun = 0;
    pipesThisRun = 0;
    combo = 0;
    bestComboThisRun = 0;
    _flightSeconds = 0;
    _pipeTimer = 0;
    _pipesSincePowerUp = 0;
    isNewHighScore = false;
    madeLeaderboard = false;
    newlyUnlocked = [];
    _resetTimers();
    _scoreText.updateScore(0);
    bird.reset();

    state = GameState.ready;
    overlays.add('hud');
    overlays.add('ready');
    AudioManager.instance.startMusic();
  }

  void _beginPlaying() {
    overlays.remove('ready');
    state = GameState.playing;
    bird.flap();
    AudioManager.instance.playFlap();
  }

  void goHome() {
    _clearRunComponents();
    overlays.remove('paused');
    overlays.remove('gameOver');
    overlays.remove('hud');
    overlays.remove('ready');
    _resetTimers();
    state = GameState.menu;
    bird.reset();
    AudioManager.instance.pauseMusic();
    overlays.add('menu');
  }

  void pauseGame() {
    if (state != GameState.playing) return;
    state = GameState.paused;
    AudioManager.instance.pauseMusic();
    overlays.add('paused');
  }

  void resumeGame() {
    if (state != GameState.paused) return;
    overlays.remove('paused');
    state = GameState.playing;
    AudioManager.instance.startMusic();
  }

  /// Called by a pipe when the bird passes it.
  void increaseScore() {
    pipesThisRun++;
    combo++;
    if (combo > bestComboThisRun) bestComboThisRun = combo;

    final int gained = comboMultiplier * (isDoubleScore ? 2 : 1);
    score += gained;
    _scoreText.updateScore(score);
    AudioManager.instance.playScore();

    // Show combo popup on milestone multipliers.
    if (combo > 0 && combo % comboStep == 0) {
      add(FloatingText(
        text: 'COMBO x$comboMultiplier',
        position: bird.position.clone()..y -= 40,
        color: const Color(0xFFFFD54F),
        fontSize: 24,
      ));
      HapticFeedback.selectionClick();
    }
  }

  void onShieldConsumed() {
    _haptic(() => HapticFeedback.lightImpact());
    AudioManager.instance.playHit();
    combo = 0; // breaking through a pipe resets the streak
    add(ParticleBurst(
      position: bird.position.clone(),
      color: const Color(0xFF29B6F6),
      count: 14,
    ));
  }

  void collectCoin(Vector2 at) {
    coinsThisRun++;
    AudioManager.instance.playScore();
    add(ParticleBurst(
      position: at,
      color: const Color(0xFFFFC107),
      count: 8,
      speed: 110,
      life: 0.4,
    ));
  }

  void collectPowerUp(PowerUpType type) {
    AudioManager.instance.playPowerUp();
    _haptic(() => HapticFeedback.selectionClick());

    String label;
    switch (type) {
      case PowerUpType.shield:
        bird.grantShield(shieldDuration);
        label = 'SHIELD';
        break;
      case PowerUpType.slowMo:
        slowMoTime = max(slowMoTime, slowMoDuration);
        label = 'SLOW-MO';
        break;
      case PowerUpType.magnet:
        magnetTime = max(magnetTime, magnetDuration);
        label = 'MAGNET';
        break;
      case PowerUpType.mini:
        miniTime = max(miniTime, miniDuration);
        label = 'MINI';
        break;
      case PowerUpType.doubleScore:
        doubleScoreTime = max(doubleScoreTime, doubleScoreDuration);
        label = 'DOUBLE!';
        break;
    }
    add(FloatingText(
      text: label,
      position: bird.position.clone()..y -= 44,
      color: PowerUp.colorForPublic(type),
      fontSize: 22,
    ));
  }

  Future<void> gameOver() async {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    bird.die();

    AudioManager.instance.playHit();
    AudioManager.instance.pauseMusic();
    _haptic(() => HapticFeedback.mediumImpact());

    add(ParticleBurst(
      position: bird.position.clone(),
      color: const Color(0xFFFF7043),
      count: 18,
      speed: 200,
      life: 0.6,
      particleSize: 5,
    ));

    // Persist coins earned this run.
    await GameStorage.instance.addCoins(coinsThisRun);

    isNewHighScore = await GameStorage.instance.maybeSaveHighScore(score);
    madeLeaderboard = await GameStorage.instance.addScore(score);
    highScore = GameStorage.instance.highScore;

    newlyUnlocked = await GameStorage.instance.recordGameResult(
      score: score,
      pipes: pipesThisRun,
      coinsCollected: coinsThisRun,
      bestCombo: bestComboThisRun,
      flightSeconds: _flightSeconds,
    );

    overlays.remove('hud');
    overlays.remove('paused');
    overlays.add('gameOver');
  }

  void _haptic(void Function() fn) {
    if (GameStorage.instance.vibrationEnabled) fn();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;

    _flightSeconds += dt;
    if (slowMoTime > 0) slowMoTime -= dt;
    if (magnetTime > 0) magnetTime -= dt;
    if (miniTime > 0) miniTime -= dt;
    if (doubleScoreTime > 0) doubleScoreTime -= dt;

    _pipeTimer += dt;
    if (_pipeTimer >= pipeInterval) {
      _pipeTimer = 0;
      _spawnPipe();
    }
  }

  void _spawnPipe() {
    const double topMargin = 80;
    final double groundTop = size.y - Ground.groundHeight;
    final double gap = pipeGap;
    final double minCenter = topMargin + gap / 2;
    final double maxCenter = groundTop - gap / 2 - 40;
    final double gapCenter =
        minCenter + _random.nextDouble() * (maxCenter - minCenter);

    add(PipePair(gapCenter: gapCenter, gap: gap));

    // Spawn a small arc of coins in the gap most of the time.
    if (_random.nextDouble() < 0.7) {
      final int n = 1 + _random.nextInt(3);
      for (int i = 0; i < n; i++) {
        add(Coin(
          position: Vector2(size.x + 150 + i * 34.0, gapCenter),
        ));
      }
    }

    // Occasionally spawn a power-up (random among all 5 types).
    _pipesSincePowerUp++;
    if (_pipesSincePowerUp >= 4 && _random.nextDouble() < 0.45) {
      _pipesSincePowerUp = 0;
      final type = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
      add(PowerUp(
        type: type,
        position: Vector2(size.x + 220, gapCenter),
      ));
    }
  }

  @override
  void onTap() {
    switch (state) {
      case GameState.ready:
        _beginPlaying();
        break;
      case GameState.playing:
        bird.flap();
        AudioManager.instance.playFlap();
        break;
      case GameState.menu:
      case GameState.paused:
      case GameState.gameOver:
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

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import '../game/themes.dart';
import '../services/game_storage.dart';

/// Sky background that smoothly transitions from day to night as the player's
/// difficulty (score) increases, with clouds by day and stars + moon by night.
/// Palette comes from the player's selected [GameTheme].
class Background extends PositionComponent with HasGameReference<FlappyGame> {
  Background();

  final math.Random _rng = math.Random(42);
  late final List<Offset> _stars;

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -10; // Always behind everything.
    _stars = List.generate(
      40,
      (_) => Offset(_rng.nextDouble(), _rng.nextDouble() * 0.6),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // How "night" it is: 0 in menu, ramps with difficulty during play.
    final double night =
        game.state == GameState.menu ? 0.0 : game.difficulty;

    final theme = GameTheme.byIndex(GameStorage.instance.theme);
    final Color top = Color.lerp(theme.dayTop, theme.nightTop, night)!;
    final Color bottom = Color.lerp(theme.dayBottom, theme.nightBottom, night)!;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Stars fade in at night.
    if (night > 0.05) {
      final starPaint = Paint()..color = Colors.white.withOpacity(night);
      for (final s in _stars) {
        canvas.drawCircle(
          Offset(s.dx * size.x, s.dy * size.y),
          1.4,
          starPaint,
        );
      }
      // Moon.
      final moonPaint = Paint()
        ..color = const Color(0xFFF5F3CE).withOpacity(night);
      canvas.drawCircle(Offset(size.x * 0.82, size.y * 0.16), 26, moonPaint);
    }

    // Clouds fade out at night.
    final double cloudAlpha = (1 - night) * 0.85;
    if (cloudAlpha > 0.02) {
      final cloudPaint = Paint()..color = Colors.white.withOpacity(cloudAlpha);
      _cloud(canvas, cloudPaint, size.x * 0.2, size.y * 0.18, 34);
      _cloud(canvas, cloudPaint, size.x * 0.7, size.y * 0.12, 26);
      _cloud(canvas, cloudPaint, size.x * 0.85, size.y * 0.3, 30);
    }
  }

  void _cloud(Canvas canvas, Paint paint, double x, double y, double r) {
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r * 0.8, y + 4), r * 0.8, paint);
    canvas.drawCircle(Offset(x - r * 0.8, y + 6), r * 0.7, paint);
    canvas.drawRect(
      Rect.fromLTWH(x - r * 1.5, y + 4, r * 3, r * 0.9),
      paint,
    );
  }
}

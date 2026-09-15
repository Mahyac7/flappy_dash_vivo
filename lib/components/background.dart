import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';

/// Sky background that smoothly transitions from day to night as the player's
/// difficulty (score) increases, with clouds by day and stars + moon by night.
class Background extends PositionComponent with HasGameReference<FlappyGame> {
  Background();

  // Day palette.
  static const Color _dayTop = Color(0xFF4EC0CA);
  static const Color _dayBottom = Color(0xFF9BE0E6);
  // Night palette.
  static const Color _nightTop = Color(0xFF0B1E3B);
  static const Color _nightBottom = Color(0xFF264A73);

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

    final Color top = Color.lerp(_dayTop, _nightTop, night)!;
    final Color bottom = Color.lerp(_dayBottom, _nightBottom, night)!;

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

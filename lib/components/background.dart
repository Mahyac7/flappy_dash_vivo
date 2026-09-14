import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';

/// A simple static sky background with a few decorative clouds.
class Background extends PositionComponent with HasGameReference<FlappyGame> {
  Background();

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -10; // Always behind everything.
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Sky gradient.
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4EC0CA), Color(0xFF9BE0E6)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // A few soft clouds.
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.85);
    _cloud(canvas, cloudPaint, size.x * 0.2, size.y * 0.18, 34);
    _cloud(canvas, cloudPaint, size.x * 0.7, size.y * 0.12, 26);
    _cloud(canvas, cloudPaint, size.x * 0.85, size.y * 0.3, 30);
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

import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import 'bird.dart';

/// Types of collectible power-ups.
enum PowerUpType { shield, slowMo, magnet, mini, doubleScore }

/// A floating collectible that moves left with the world. When the bird
/// touches it, it applies its effect and disappears.
class PowerUp extends PositionComponent
    with HasGameReference<FlappyGame>, CollisionCallbacks {
  PowerUp({required this.type, required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(34),
          anchor: Anchor.center,
        );

  final PowerUpType type;

  double _bob = 0;
  bool _collected = false;

  static const double radius = 17;

  @override
  Future<void> onLoad() async {
    priority = 3;
    add(CircleHitbox(
      radius: radius,
      position: size / 2,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    position.x -= game.worldSpeed * dt;
    _bob += dt * 3;

    if (position.x + radius < -20) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_collected) return;
    // Only react to the bird (its hitbox is a child of Bird).
    final isBird = other is Bird || other.parent is Bird;
    if (!isBird) return;
    _collected = true;
    game.collectPowerUp(type);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2 + math.sin(_bob) * 2);

    final Color color = _colorFor(type);

    // Glow.
    canvas.drawCircle(
      center,
      radius + 3,
      Paint()..color = color.withOpacity(0.3),
    );
    // Body.
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawIcon(canvas, center);
  }

  /// Public accessor for a power-up type's colour (used by UI popups).
  static Color colorForPublic(PowerUpType t) => _colorFor(t);

  static Color _colorFor(PowerUpType t) {
    switch (t) {
      case PowerUpType.shield:
        return const Color(0xFF29B6F6);
      case PowerUpType.slowMo:
        return const Color(0xFFAB47BC);
      case PowerUpType.magnet:
        return const Color(0xFFEF5350);
      case PowerUpType.mini:
        return const Color(0xFF26A69A);
      case PowerUpType.doubleScore:
        return const Color(0xFFFFA726);
    }
  }

  void _drawIcon(Canvas canvas, Offset c) {
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = Colors.white;

    switch (type) {
      case PowerUpType.shield:
        final p = Path()
          ..moveTo(c.dx, c.dy - 8)
          ..lineTo(c.dx + 7, c.dy - 4)
          ..lineTo(c.dx + 7, c.dy + 3)
          ..lineTo(c.dx, c.dy + 9)
          ..lineTo(c.dx - 7, c.dy + 3)
          ..lineTo(c.dx - 7, c.dy - 4)
          ..close();
        canvas.drawPath(p, iconPaint);
        break;
      case PowerUpType.slowMo:
        canvas.drawCircle(c, 7, iconPaint);
        canvas.drawLine(c, Offset(c.dx, c.dy - 5), iconPaint);
        canvas.drawLine(c, Offset(c.dx + 4, c.dy), iconPaint);
        break;
      case PowerUpType.magnet:
        // U-shaped magnet.
        final rect = Rect.fromCenter(center: c, width: 14, height: 14);
        canvas.drawArc(rect, 3.14, 3.14, false, iconPaint..strokeWidth = 3);
        canvas.drawLine(
            Offset(c.dx - 7, c.dy), Offset(c.dx - 7, c.dy + 6), iconPaint);
        canvas.drawLine(
            Offset(c.dx + 7, c.dy), Offset(c.dx + 7, c.dy + 6), iconPaint);
        break;
      case PowerUpType.mini:
        // Down arrows (shrink).
        canvas.drawCircle(c, 4, fill);
        final p = Path()
          ..moveTo(c.dx - 8, c.dy - 2)
          ..lineTo(c.dx, c.dy + 8)
          ..lineTo(c.dx + 8, c.dy - 2);
        canvas.drawPath(p, iconPaint);
        break;
      case PowerUpType.doubleScore:
        // "x2" text-like glyph drawn simply.
        final tp = TextPainter(
          text: const TextSpan(
            text: 'x2',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
        break;
    }
  }
}

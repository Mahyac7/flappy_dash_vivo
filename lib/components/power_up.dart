import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import 'bird.dart';

/// Types of collectible power-ups.
enum PowerUpType { shield, slowMo }

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

    final Color color = type == PowerUpType.shield
        ? const Color(0xFF29B6F6)
        : const Color(0xFFAB47BC);

    // Glow.
    canvas.drawCircle(
      center,
      radius + 3,
      Paint()..color = color.withOpacity(0.3),
    );
    // Coin.
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Icon.
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (type == PowerUpType.shield) {
      // Simple shield outline.
      final p = Path()
        ..moveTo(center.dx, center.dy - 8)
        ..lineTo(center.dx + 7, center.dy - 4)
        ..lineTo(center.dx + 7, center.dy + 3)
        ..lineTo(center.dx, center.dy + 9)
        ..lineTo(center.dx - 7, center.dy + 3)
        ..lineTo(center.dx - 7, center.dy - 4)
        ..close();
      canvas.drawPath(p, iconPaint);
    } else {
      // Clock face for slow-mo.
      canvas.drawCircle(center, 7, iconPaint);
      canvas.drawLine(center, Offset(center.dx, center.dy - 5), iconPaint);
      canvas.drawLine(center, Offset(center.dx + 4, center.dy), iconPaint);
    }
  }
}

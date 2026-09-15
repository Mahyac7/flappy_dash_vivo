import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import 'bird.dart';

/// A collectible coin. Moves left with the world, spins for flair, and is
/// attracted toward the bird while the magnet power-up is active.
class Coin extends PositionComponent
    with HasGameReference<FlappyGame>, CollisionCallbacks {
  Coin({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(26),
          anchor: Anchor.center,
        );

  static const double radius = 13;

  double _spin = 0;
  bool _collected = false;

  @override
  Future<void> onLoad() async {
    priority = 2;
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
    _spin += dt * 5;

    // Magnet effect: drift toward the bird.
    if (game.isMagnet) {
      final target = game.bird.position;
      final dir = target - position;
      if (dir.length < 220) {
        dir.normalize();
        position += dir * 260 * dt;
      }
    }

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
    final isBird = other is Bird || other.parent is Bird;
    if (!isBird) return;
    _collected = true;
    game.collectCoin(position.clone());
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    // Squash horizontally to fake a spin.
    final double sx = (math.cos(_spin)).abs().clamp(0.25, 1.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(sx, 1.0);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset.zero, radius * 0.55,
        Paint()..color = const Color(0xFFFFE082));
    canvas.restore();
  }
}

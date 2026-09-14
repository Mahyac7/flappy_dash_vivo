import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import 'ground.dart';

/// The player-controlled bird.
///
/// Falls under gravity and gets an upward impulse on each flap. Drawn as a
/// simple round body with an eye, a beak and a wing so no image assets are
/// required.
class Bird extends PositionComponent
    with HasGameReference<FlappyGame>, CollisionCallbacks {
  Bird() : super(size: Vector2(46, 34), anchor: Anchor.center);

  double _velocity = 0;
  bool _alive = true;

  static const double _radius = 17;

  @override
  Future<void> onLoad() async {
    add(
      CircleHitbox(
        radius: _radius,
        position: size / 2,
        anchor: Anchor.center,
      ),
    );
    reset();
  }

  /// Places the bird back at its starting position.
  void reset() {
    _alive = true;
    _velocity = 0;
    angle = 0;
    position = Vector2(game.size.x * 0.28, game.size.y * 0.42);
  }

  /// Applies an upward impulse.
  void flap() {
    if (!_alive) return;
    _velocity = FlappyGame.flapVelocity;
  }

  /// Stops the bird from being controllable after a crash.
  void die() {
    _alive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing && _alive) return;

    _velocity += FlappyGame.gravity * dt;
    position.y += _velocity * dt;

    // Tilt the bird based on vertical velocity for a nicer feel.
    angle = (_velocity / 900).clamp(-0.5, 1.4);

    // Ceiling clamp.
    if (position.y < size.y / 2) {
      position.y = size.y / 2;
      _velocity = 0;
    }

    // Hitting the ground ends the game.
    final double groundTop = game.size.y - Ground.groundHeight;
    if (position.y + _radius >= groundTop) {
      position.y = groundTop - _radius;
      game.gameOver();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    game.gameOver();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Offset center = Offset(size.x / 2, size.y / 2);

    // Body.
    final bodyPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(center, _radius, bodyPaint);

    // Body outline.
    final outline = Paint()
      ..color = const Color(0xFF8D6E00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, _radius, outline);

    // Wing.
    final wingPaint = Paint()..color = const Color(0xFFFFF3C4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 4, center.dy + 3),
        width: 20,
        height: 12,
      ),
      wingPaint,
    );

    // Beak.
    final beakPaint = Paint()..color = const Color(0xFFFF7043);
    final beak = Path()
      ..moveTo(center.dx + _radius - 2, center.dy - 4)
      ..lineTo(center.dx + _radius + 9, center.dy)
      ..lineTo(center.dx + _radius - 2, center.dy + 4)
      ..close();
    canvas.drawPath(beak, beakPaint);

    // Eye.
    canvas.drawCircle(
      Offset(center.dx + 6, center.dy - 6),
      5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(center.dx + 8, center.dy - 6),
      2.4,
      Paint()..color = Colors.black,
    );
  }
}


import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/bird_skins.dart';
import '../game/flappy_game.dart';
import '../services/game_storage.dart';
import 'ground.dart';
import 'pipe_pair.dart';
import 'power_up.dart';

/// The player-controlled bird.
///
/// Falls under gravity and gets an upward impulse on each flap. Drawn as a
/// round body with an eye, a beak and a wing so no image assets are required.
/// Colours come from the player's selected [BirdSkin].
class Bird extends PositionComponent
    with HasGameReference<FlappyGame>, CollisionCallbacks {
  Bird() : super(size: Vector2(46, 34), anchor: Anchor.center);

  double _velocity = 0;
  bool _alive = true;

  /// Remaining shield time in seconds (0 = no shield).
  double shieldTime = 0;
  double _shieldPulse = 0;
  double _hoverPhase = 0;
  double _baseY = 0;

  bool get hasShield => shieldTime > 0;

  static const double _radius = 17;

  /// Visual + hitbox scale (shrinks with the mini power-up).
  double get _scaleFactor => game.isMini ? 0.62 : 1.0;

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
    shieldTime = 0;
    angle = 0;
    _hoverPhase = 0;
    scale = Vector2.all(1);
    position = Vector2(game.size.x * 0.28, game.size.y * 0.42);
    _baseY = position.y;
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

  /// Grants a temporary shield that absorbs one obstacle hit.
  void grantShield(double seconds) {
    shieldTime = math.max(shieldTime, seconds);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smoothly apply the mini power-up scale.
    scale = Vector2.all(_scaleFactor);

    // Tap-to-start: hover gently, no gravity yet.
    if (game.state == GameState.ready) {
      _hoverPhase += dt * 3;
      position.y = _baseY + math.sin(_hoverPhase) * 8;
      angle = 0;
      return;
    }

    if (game.state != GameState.playing && _alive) return;

    if (shieldTime > 0) {
      shieldTime -= dt;
      _shieldPulse += dt * 6;
    }

    _velocity += FlappyGame.gravity * dt;
    position.y += _velocity * dt;

    // Tilt the bird based on vertical velocity for a nicer feel.
    angle = (_velocity / 900).clamp(-0.5, 1.4);

    // Ceiling clamp.
    if (position.y < size.y / 2) {
      position.y = size.y / 2;
      _velocity = 0;
    }

    // Hitting the ground always ends the game (shield doesn't save you here).
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

    // Power-up pickup is handled by the power-up itself; ignore here.
    if (other is PowerUp || other.parent is PowerUp) return;

    // Colliding with a pipe: the pipe hitbox lives inside a _Pipe which lives
    // inside a PipePair. Walk up to see if this is part of a pipe.
    final bool isPipe = _isDescendantOfPipePair(other);
    if (isPipe) {
      if (hasShield) {
        shieldTime = 0;
        game.onShieldConsumed();
        return;
      }
      game.gameOver();
    }
  }

  bool _isDescendantOfPipePair(Component c) {
    Component? current = c;
    while (current != null) {
      if (current is PipePair) return true;
      current = current.parent;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Offset center = Offset(size.x / 2, size.y / 2);
    final skin = BirdSkin.byIndex(GameStorage.instance.birdSkin);

    // Body.
    canvas.drawCircle(center, _radius, Paint()..color = skin.body);

    // Body outline.
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..color = skin.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Wing.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 4, center.dy + 3),
        width: 20,
        height: 12,
      ),
      Paint()..color = skin.bodyLight,
    );

    // Beak.
    final beak = Path()
      ..moveTo(center.dx + _radius - 2, center.dy - 4)
      ..lineTo(center.dx + _radius + 9, center.dy)
      ..lineTo(center.dx + _radius - 2, center.dy + 4)
      ..close();
    canvas.drawPath(beak, Paint()..color = skin.beak);

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

    // Shield bubble.
    if (hasShield) {
      final double alpha = 0.35 + 0.25 * (0.5 + 0.5 * math.sin(_shieldPulse));
      canvas.drawCircle(
        center,
        _radius + 7,
        Paint()
          ..color = const Color(0xFF29B6F6).withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}

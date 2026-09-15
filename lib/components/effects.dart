import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A short-lived burst of particles (used for coin pickups and crashes).
class ParticleBurst extends PositionComponent {
  ParticleBurst({
    required Vector2 position,
    required this.color,
    this.count = 10,
    this.speed = 140,
    this.life = 0.5,
    this.particleSize = 4,
  }) : super(position: position, priority: 30);

  final Color color;
  final int count;
  final double speed;
  final double life;
  final double particleSize;

  final List<_P> _parts = [];
  double _age = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final spd = speed * (0.4 + rng.nextDouble() * 0.6);
      _parts.add(_P(
        vx: math.cos(angle) * spd,
        vy: math.sin(angle) * spd,
        x: 0,
        y: 0,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final p in _parts) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 260 * dt; // gravity
    }
    if (_age >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (1 - _age / life).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withOpacity(t);
    for (final p in _parts) {
      canvas.drawCircle(Offset(p.x, p.y), particleSize * t + 1, paint);
    }
  }
}

class _P {
  _P({required this.vx, required this.vy, required this.x, required this.y});
  double vx, vy, x, y;
}

/// A floating text that rises and fades (e.g. "+1", "COMBO x3", "+5 coins").
class FloatingText extends TextComponent {
  FloatingText({
    required String text,
    required Vector2 position,
    Color color = Colors.white,
    double fontSize = 22,
    this.life = 0.8,
    this.rise = 60,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          priority: 31,
          textRenderer: TextPaint(
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 1)),
              ],
            ),
          ),
        );

  final double life;
  final double rise;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= rise * dt;
    if (_age >= life) removeFromParent();
  }
}

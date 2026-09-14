import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import 'ground.dart';

/// A pair of pipes (top + bottom) with a gap the bird must fly through.
///
/// Moves left across the screen, awards a point once the bird passes it and
/// removes itself once fully off-screen.
class PipePair extends PositionComponent with HasGameReference<FlappyGame> {
  PipePair({required this.gapCenter});

  /// Vertical center of the gap, in world coordinates.
  final double gapCenter;

  static const double pipeWidth = 70;

  bool _scored = false;

  @override
  Future<void> onLoad() async {
    width = pipeWidth;
    height = game.size.y;
    position = Vector2(game.size.x + pipeWidth, 0);

    const double gap = FlappyGame.pipeGap;
    final double groundTop = game.size.y - Ground.groundHeight;

    final double topHeight = gapCenter - gap / 2;
    final double bottomTop = gapCenter + gap / 2;

    // Top pipe.
    add(_Pipe(
      isTop: true,
      position: Vector2(0, 0),
      size: Vector2(pipeWidth, topHeight),
    ));

    // Bottom pipe.
    add(_Pipe(
      isTop: false,
      position: Vector2(0, bottomTop),
      size: Vector2(pipeWidth, groundTop - bottomTop),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    position.x -= FlappyGame.worldSpeed * dt;

    // Score once the bird's x passes the right edge of the pipe.
    if (!_scored && position.x + pipeWidth < game.bird.position.x) {
      _scored = true;
      game.increaseScore();
    }

    // Clean up once off-screen to the left.
    if (position.x + pipeWidth < -20) {
      removeFromParent();
    }
  }
}

/// A single pipe rectangle with a hitbox and a decorative rim.
class _Pipe extends PositionComponent {
  _Pipe({
    required this.isTop,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  final bool isTop;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.y <= 0) return;

    final bodyPaint = Paint()..color = const Color(0xFF5BA31F);
    final rimPaint = Paint()..color = const Color(0xFF3E7A14);
    final highlightPaint = Paint()..color = const Color(0xFF7ED03A);

    // Main pipe body.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bodyPaint);

    // Vertical highlight stripe.
    canvas.drawRect(Rect.fromLTWH(6, 0, 8, size.y), highlightPaint);

    // Rim (a wider cap at the mouth of the pipe).
    const double rimHeight = 22;
    const double rimOverhang = 6;
    final double rimY = isTop ? size.y - rimHeight : 0;
    canvas.drawRect(
      Rect.fromLTWH(-rimOverhang, rimY, size.x + rimOverhang * 2, rimHeight),
      rimPaint,
    );
  }
}

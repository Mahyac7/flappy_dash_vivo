import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';
import '../game/themes.dart';
import '../services/game_storage.dart';
import 'ground.dart';

/// A pair of pipes (top + bottom) with a gap the bird must fly through.
///
/// Moves left across the screen, awards a point once the bird passes it and
/// removes itself once fully off-screen.
class PipePair extends PositionComponent with HasGameReference<FlappyGame> {
  PipePair({required this.gapCenter, required this.gap});

  /// Vertical center of the gap, in world coordinates.
  final double gapCenter;

  /// Height of the gap for this pair (varies with difficulty).
  final double gap;

  static const double pipeWidth = 70;

  bool _scored = false;

  @override
  Future<void> onLoad() async {
    width = pipeWidth;
    height = game.size.y;
    position = Vector2(game.size.x + pipeWidth, 0);

    final double groundTop = game.size.y - Ground.groundHeight;

    final double topHeight = gapCenter - gap / 2;
    final double bottomTop = gapCenter + gap / 2;

    final theme = GameTheme.byIndex(GameStorage.instance.theme);

    // Top pipe.
    add(_Pipe(
      isTop: true,
      theme: theme,
      position: Vector2(0, 0),
      size: Vector2(pipeWidth, topHeight),
    ));

    // Bottom pipe.
    add(_Pipe(
      isTop: false,
      theme: theme,
      position: Vector2(0, bottomTop),
      size: Vector2(pipeWidth, groundTop - bottomTop),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    position.x -= game.worldSpeed * dt;

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
    required this.theme,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  final bool isTop;
  final GameTheme theme;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.y <= 0) return;

    final bodyPaint = Paint()..color = theme.pipeBody;
    final rimPaint = Paint()..color = theme.pipeRim;
    final highlightPaint = Paint()..color = theme.pipeHighlight;

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

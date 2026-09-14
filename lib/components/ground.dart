import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';

/// The scrolling ground strip at the bottom of the screen.
class Ground extends PositionComponent with HasGameReference<FlappyGame> {
  Ground();

  /// Height of the ground area in logical pixels.
  static const double groundHeight = 120;

  double _offset = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(game.size.x, groundHeight);
    position = Vector2(0, game.size.y - groundHeight);
    priority = 5; // Draw above pipes.
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(size.x, groundHeight);
    position = Vector2(0, size.y - groundHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state == GameState.playing) {
      _offset = (_offset + FlappyGame.worldSpeed * dt) % 24;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Grass strip.
    final grassPaint = Paint()..color = const Color(0xFF73BF2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 16), grassPaint);

    // Dirt.
    final dirtPaint = Paint()..color = const Color(0xFFDED895);
    canvas.drawRect(Rect.fromLTWH(0, 16, size.x, size.y - 16), dirtPaint);

    // Moving dashes on the grass for a sense of speed.
    final dashPaint = Paint()..color = const Color(0xFF5BA31F);
    for (double x = -24 + _offset; x < size.x; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, 12, 12, 4), dashPaint);
    }
  }
}

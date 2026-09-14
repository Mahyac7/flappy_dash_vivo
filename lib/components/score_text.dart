import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/flappy_game.dart';

/// Displays the current score near the top of the screen while playing.
class ScoreText extends TextComponent with HasGameReference<FlappyGame> {
  ScoreText()
      : super(
          text: '0',
          anchor: Anchor.topCenter,
          priority: 20,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    _reposition();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _reposition();
  }

  void _reposition() {
    position = Vector2(game.size.x / 2, 60);
  }

  /// Updates the displayed score, hiding it entirely outside of play.
  void updateScore(int value) {
    text = '$value';
  }

  @override
  void render(Canvas canvas) {
    // Only show the score during active play.
    if (game.state == GameState.playing) {
      super.render(canvas);
    }
  }
}

import 'package:flutter/material.dart';

/// A visual theme controlling pipe colours and the day/night sky palette.
class GameTheme {
  const GameTheme({
    required this.name,
    required this.pipeBody,
    required this.pipeRim,
    required this.pipeHighlight,
    required this.dayTop,
    required this.dayBottom,
    required this.nightTop,
    required this.nightBottom,
  });

  final String name;

  final Color pipeBody;
  final Color pipeRim;
  final Color pipeHighlight;

  final Color dayTop;
  final Color dayBottom;
  final Color nightTop;
  final Color nightBottom;

  static const List<GameTheme> all = [
    GameTheme(
      name: 'Classic',
      pipeBody: Color(0xFF5BA31F),
      pipeRim: Color(0xFF3E7A14),
      pipeHighlight: Color(0xFF7ED03A),
      dayTop: Color(0xFF4EC0CA),
      dayBottom: Color(0xFF9BE0E6),
      nightTop: Color(0xFF0B1E3B),
      nightBottom: Color(0xFF264A73),
    ),
    GameTheme(
      name: 'Sunset',
      pipeBody: Color(0xFFEF7043),
      pipeRim: Color(0xFFBF360C),
      pipeHighlight: Color(0xFFFFA270),
      dayTop: Color(0xFFFF9E80),
      dayBottom: Color(0xFFFFD180),
      nightTop: Color(0xFF3E1F47),
      nightBottom: Color(0xFF7B2E5D),
    ),
    GameTheme(
      name: 'Candy',
      pipeBody: Color(0xFFEC407A),
      pipeRim: Color(0xFFAD1457),
      pipeHighlight: Color(0xFFF48FB1),
      dayTop: Color(0xFFF8BBD0),
      dayBottom: Color(0xFFE1BEE7),
      nightTop: Color(0xFF4A148C),
      nightBottom: Color(0xFF880E4F),
    ),
    GameTheme(
      name: 'Ocean',
      pipeBody: Color(0xFF26A69A),
      pipeRim: Color(0xFF00695C),
      pipeHighlight: Color(0xFF64D8CB),
      dayTop: Color(0xFF4DD0E1),
      dayBottom: Color(0xFFB2EBF2),
      nightTop: Color(0xFF002B36),
      nightBottom: Color(0xFF01579B),
    ),
  ];

  static GameTheme byIndex(int i) => all[i.clamp(0, all.length - 1)];
}

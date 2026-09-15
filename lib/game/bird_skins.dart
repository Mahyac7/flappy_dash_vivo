import 'package:flutter/material.dart';

/// A selectable colour scheme for the bird.
class BirdSkin {
  const BirdSkin({
    required this.name,
    required this.body,
    required this.bodyLight,
    required this.outline,
    required this.beak,
  });

  final String name;
  final Color body;
  final Color bodyLight;
  final Color outline;
  final Color beak;

  /// All available skins. Index maps to the persisted `birdSkin` value.
  static const List<BirdSkin> all = [
    BirdSkin(
      name: 'Classic',
      body: Color(0xFFFFD54F),
      bodyLight: Color(0xFFFFF3C4),
      outline: Color(0xFF8D6E00),
      beak: Color(0xFFFF7043),
    ),
    BirdSkin(
      name: 'Sky',
      body: Color(0xFF4FC3F7),
      bodyLight: Color(0xFFB3E5FC),
      outline: Color(0xFF01579B),
      beak: Color(0xFFFFB300),
    ),
    BirdSkin(
      name: 'Coral',
      body: Color(0xFFFF6E7F),
      bodyLight: Color(0xFFFFC1CC),
      outline: Color(0xFF9B1B30),
      beak: Color(0xFFFFD54F),
    ),
    BirdSkin(
      name: 'Mint',
      body: Color(0xFF66BB6A),
      bodyLight: Color(0xFFC8E6C9),
      outline: Color(0xFF1B5E20),
      beak: Color(0xFFFF7043),
    ),
    BirdSkin(
      name: 'Grape',
      body: Color(0xFFBA68C8),
      bodyLight: Color(0xFFE1BEE7),
      outline: Color(0xFF4A148C),
      beak: Color(0xFFFFD54F),
    ),
    BirdSkin(
      name: 'Shadow',
      body: Color(0xFF546E7A),
      bodyLight: Color(0xFFB0BEC5),
      outline: Color(0xFF212121),
      beak: Color(0xFFFF7043),
    ),
  ];

  static BirdSkin byIndex(int i) => all[i.clamp(0, all.length - 1)];
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single leaderboard entry.
class ScoreEntry {
  ScoreEntry({required this.name, required this.score, required this.date});

  final String name;
  final int score;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'date': date.toIso8601String(),
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
        name: (json['name'] as String?) ?? 'Player',
        score: (json['score'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Persists player data (high score, preferences, chosen skin, name and a
/// local top-5 leaderboard) across app launches using [SharedPreferences].
class GameStorage {
  GameStorage._();

  static final GameStorage instance = GameStorage._();

  static const String _kHighScore = 'high_score';
  static const String _kSoundEnabled = 'sound_enabled';
  static const String _kMusicEnabled = 'music_enabled';
  static const String _kBirdSkin = 'bird_skin';
  static const String _kPlayerName = 'player_name';
  static const String _kLeaderboard = 'leaderboard';

  static const int maxLeaderboardEntries = 5;

  SharedPreferences? _prefs;

  int highScore = 0;
  bool soundEnabled = true;
  bool musicEnabled = true;
  int birdSkin = 0;
  String playerName = 'Player';
  List<ScoreEntry> leaderboard = [];

  /// Loads persisted values. Call once during app startup.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    highScore = _prefs?.getInt(_kHighScore) ?? 0;
    soundEnabled = _prefs?.getBool(_kSoundEnabled) ?? true;
    musicEnabled = _prefs?.getBool(_kMusicEnabled) ?? true;
    birdSkin = _prefs?.getInt(_kBirdSkin) ?? 0;
    playerName = _prefs?.getString(_kPlayerName) ?? 'Player';
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    final raw = _prefs?.getString(_kLeaderboard);
    if (raw == null || raw.isEmpty) {
      leaderboard = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      leaderboard = list
          .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      leaderboard = [];
    }
  }

  /// Saves a new high score only if it beats the stored one.
  /// Returns true if a new record was set.
  Future<bool> maybeSaveHighScore(int score) async {
    if (score > highScore) {
      highScore = score;
      await _prefs?.setInt(_kHighScore, score);
      return true;
    }
    return false;
  }

  /// Adds a score to the local leaderboard, keeping only the top entries.
  /// Returns true if it made it onto the board.
  Future<bool> addScore(int score) async {
    if (score <= 0) return false;
    final entry = ScoreEntry(
      name: playerName,
      score: score,
      date: DateTime.now(),
    );
    leaderboard.add(entry);
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    final madeIt = leaderboard.indexOf(entry) < maxLeaderboardEntries;
    if (leaderboard.length > maxLeaderboardEntries) {
      leaderboard = leaderboard.sublist(0, maxLeaderboardEntries);
    }
    await _prefs?.setString(
      _kLeaderboard,
      jsonEncode(leaderboard.map((e) => e.toJson()).toList()),
    );
    return madeIt;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _prefs?.setBool(_kSoundEnabled, enabled);
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    await _prefs?.setBool(_kMusicEnabled, enabled);
  }

  Future<void> setBirdSkin(int skin) async {
    birdSkin = skin;
    await _prefs?.setInt(_kBirdSkin, skin);
  }

  Future<void> setPlayerName(String name) async {
    final trimmed = name.trim();
    playerName = trimmed.isEmpty ? 'Player' : trimmed;
    await _prefs?.setString(_kPlayerName, playerName);
  }
}

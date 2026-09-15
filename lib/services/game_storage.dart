import 'package:shared_preferences/shared_preferences.dart';

/// Persists player data (high score and sound preference) across app launches
/// using [SharedPreferences].
class GameStorage {
  GameStorage._();

  static final GameStorage instance = GameStorage._();

  static const String _kHighScore = 'high_score';
  static const String _kSoundEnabled = 'sound_enabled';

  SharedPreferences? _prefs;

  int highScore = 0;
  bool soundEnabled = true;

  /// Loads persisted values. Call once during app startup.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    highScore = _prefs?.getInt(_kHighScore) ?? 0;
    soundEnabled = _prefs?.getBool(_kSoundEnabled) ?? true;
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

  /// Toggles the sound preference and persists it.
  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _prefs?.setBool(_kSoundEnabled, enabled);
  }
}

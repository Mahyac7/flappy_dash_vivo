import 'package:audioplayers/audioplayers.dart';

import 'game_storage.dart';

/// Handles short sound effects (via a small pool of players) and a looping
/// background-music track.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  // A few players so overlapping sfx don't interrupt one another.
  final List<AudioPlayer> _players =
      List.generate(4, (_) => AudioPlayer(playerId: 'sfx_${_playerCounter++}'));
  static int _playerCounter = 0;
  int _next = 0;

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  bool _musicStarted = false;

  bool _preloaded = false;

  /// Configures players for low-latency playback.
  Future<void> init() async {
    for (final p in _players) {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _preloaded = true;
  }

  Future<void> _play(String asset) async {
    if (!GameStorage.instance.soundEnabled) return;
    if (!_preloaded) return;
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: 0.9);
    } catch (_) {
      // Ignore audio errors so gameplay is never interrupted.
    }
  }

  Future<void> playFlap() => _play('audio/flap.wav');
  Future<void> playScore() => _play('audio/score.wav');
  Future<void> playHit() => _play('audio/hit.wav');
  Future<void> playPowerUp() => _play('audio/score.wav');

  /// Starts (or resumes) looping background music if enabled.
  Future<void> startMusic() async {
    if (!GameStorage.instance.musicEnabled) return;
    try {
      if (_musicStarted) {
        await _musicPlayer.resume();
      } else {
        await _musicPlayer.play(AssetSource('audio/music.wav'), volume: 0.35);
        _musicStarted = true;
      }
    } catch (_) {}
  }

  /// Pauses background music (e.g. on pause screen).
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  /// Stops background music entirely.
  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
      _musicStarted = false;
    } catch (_) {}
  }

  /// Applies the current music preference immediately.
  Future<void> refreshMusicPreference() async {
    if (GameStorage.instance.musicEnabled) {
      await startMusic();
    } else {
      await pauseMusic();
    }
  }
}

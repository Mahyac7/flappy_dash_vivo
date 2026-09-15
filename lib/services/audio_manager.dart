import 'package:audioplayers/audioplayers.dart';

import 'game_storage.dart';

/// Small wrapper around a pool of [AudioPlayer]s for firing short sound
/// effects without cutting each other off.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  // A few players so overlapping sounds don't interrupt one another.
  final List<AudioPlayer> _players =
      List.generate(4, (_) => AudioPlayer(playerId: 'sfx_${_playerCounter++}'));
  static int _playerCounter = 0;
  int _next = 0;

  bool _preloaded = false;

  /// Configures players for low-latency playback.
  Future<void> init() async {
    for (final p in _players) {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
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
}

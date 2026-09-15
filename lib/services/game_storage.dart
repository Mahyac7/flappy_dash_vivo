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

/// Aggregate lifetime statistics for the player.
class PlayerStats {
  int gamesPlayed = 0;
  int totalPipes = 0;
  int totalCoins = 0;
  int bestCombo = 0;
  double totalFlightSeconds = 0;

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'totalPipes': totalPipes,
        'totalCoins': totalCoins,
        'bestCombo': bestCombo,
        'totalFlightSeconds': totalFlightSeconds,
      };

  void loadFrom(Map<String, dynamic> j) {
    gamesPlayed = (j['gamesPlayed'] as num?)?.toInt() ?? 0;
    totalPipes = (j['totalPipes'] as num?)?.toInt() ?? 0;
    totalCoins = (j['totalCoins'] as num?)?.toInt() ?? 0;
    bestCombo = (j['bestCombo'] as num?)?.toInt() ?? 0;
    totalFlightSeconds = (j['totalFlightSeconds'] as num?)?.toDouble() ?? 0;
  }
}

/// Definition of an achievement (static) plus its unlocked state.
class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    this.unlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final int reward;
  bool unlocked;
}

/// Persists all player data across app launches using [SharedPreferences].
class GameStorage {
  GameStorage._();

  static final GameStorage instance = GameStorage._();

  static const String _kHighScore = 'high_score';
  static const String _kSoundEnabled = 'sound_enabled';
  static const String _kMusicEnabled = 'music_enabled';
  static const String _kVibrationEnabled = 'vibration_enabled';
  static const String _kBirdSkin = 'bird_skin';
  static const String _kPlayerName = 'player_name';
  static const String _kLeaderboard = 'leaderboard';
  static const String _kCoins = 'coins';
  static const String _kUnlockedSkins = 'unlocked_skins';
  static const String _kTheme = 'theme';
  static const String _kStats = 'stats';
  static const String _kAchievements = 'achievements_unlocked';
  static const String _kMissionDate = 'mission_date';
  static const String _kMissionProgress = 'mission_progress';
  static const String _kMissionClaimed = 'mission_claimed';
  static const String _kMissionIndex = 'mission_index';

  static const int maxLeaderboardEntries = 5;

  /// Coin price to unlock each skin index (0 = free/default).
  static const List<int> skinPrices = [0, 30, 60, 100, 150, 220];

  SharedPreferences? _prefs;

  int highScore = 0;
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool vibrationEnabled = true;
  int birdSkin = 0;
  String playerName = 'Player';
  List<ScoreEntry> leaderboard = [];

  int coins = 0;
  Set<int> unlockedSkins = {0};
  int theme = 0;
  PlayerStats stats = PlayerStats();

  // Achievements.
  final List<Achievement> achievements = [
    Achievement(
        id: 'first_flight',
        title: 'First Flight',
        description: 'Play your first game',
        reward: 10),
    Achievement(
        id: 'score_10',
        title: 'Getting the Hang',
        description: 'Score 10 in a single run',
        reward: 20),
    Achievement(
        id: 'score_25',
        title: 'Sky Master',
        description: 'Score 25 in a single run',
        reward: 40),
    Achievement(
        id: 'coins_100',
        title: 'Coin Hoarder',
        description: 'Collect 100 coins total',
        reward: 30),
    Achievement(
        id: 'combo_10',
        title: 'Combo King',
        description: 'Reach a 10x combo',
        reward: 30),
    Achievement(
        id: 'all_skins',
        title: 'Fashionista',
        description: 'Unlock every bird skin',
        reward: 50),
  ];

  // Daily mission.
  static const List<Map<String, dynamic>> _missionPool = [
    {'text': 'Pass 15 pipes today', 'goal': 15, 'reward': 25, 'type': 'pipes'},
    {'text': 'Collect 20 coins today', 'goal': 20, 'reward': 25, 'type': 'coins'},
    {'text': 'Play 3 games today', 'goal': 3, 'reward': 20, 'type': 'games'},
    {'text': 'Reach a 5x combo', 'goal': 5, 'reward': 25, 'type': 'combo'},
  ];
  int missionIndex = 0;
  int missionProgress = 0;
  bool missionClaimed = false;

  Map<String, dynamic> get mission => _missionPool[missionIndex];
  String get missionText => mission['text'] as String;
  int get missionGoal => mission['goal'] as int;
  int get missionReward => mission['reward'] as int;
  String get missionType => mission['type'] as String;
  bool get missionComplete => missionProgress >= missionGoal;

  /// Loads persisted values. Call once during app startup.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    highScore = _prefs?.getInt(_kHighScore) ?? 0;
    soundEnabled = _prefs?.getBool(_kSoundEnabled) ?? true;
    musicEnabled = _prefs?.getBool(_kMusicEnabled) ?? true;
    vibrationEnabled = _prefs?.getBool(_kVibrationEnabled) ?? true;
    birdSkin = _prefs?.getInt(_kBirdSkin) ?? 0;
    playerName = _prefs?.getString(_kPlayerName) ?? 'Player';
    coins = _prefs?.getInt(_kCoins) ?? 0;
    theme = _prefs?.getInt(_kTheme) ?? 0;

    _loadLeaderboard();
    _loadUnlockedSkins();
    _loadStats();
    _loadAchievements();
    _loadMission();
  }

  void _loadLeaderboard() {
    final raw = _prefs?.getString(_kLeaderboard);
    leaderboard = [];
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      leaderboard = list
          .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      leaderboard = [];
    }
  }

  void _loadUnlockedSkins() {
    final raw = _prefs?.getStringList(_kUnlockedSkins);
    unlockedSkins = {0};
    if (raw != null) {
      for (final s in raw) {
        final i = int.tryParse(s);
        if (i != null) unlockedSkins.add(i);
      }
    }
  }

  void _loadStats() {
    final raw = _prefs?.getString(_kStats);
    stats = PlayerStats();
    if (raw != null && raw.isNotEmpty) {
      try {
        stats.loadFrom(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  void _loadAchievements() {
    final unlockedIds = _prefs?.getStringList(_kAchievements) ?? [];
    for (final a in achievements) {
      a.unlocked = unlockedIds.contains(a.id);
    }
  }

  void _loadMission() {
    final today = _todayKey();
    final storedDate = _prefs?.getString(_kMissionDate);
    if (storedDate != today) {
      // New day → pick a rotating mission and reset progress.
      missionIndex = DateTime.now().day % _missionPool.length;
      missionProgress = 0;
      missionClaimed = false;
      _prefs?.setString(_kMissionDate, today);
      _prefs?.setInt(_kMissionIndex, missionIndex);
      _prefs?.setInt(_kMissionProgress, 0);
      _prefs?.setBool(_kMissionClaimed, false);
    } else {
      missionIndex = _prefs?.getInt(_kMissionIndex) ?? 0;
      missionProgress = _prefs?.getInt(_kMissionProgress) ?? 0;
      missionClaimed = _prefs?.getBool(_kMissionClaimed) ?? false;
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  // ---- High score / leaderboard ----

  Future<bool> maybeSaveHighScore(int score) async {
    if (score > highScore) {
      highScore = score;
      await _prefs?.setInt(_kHighScore, score);
      return true;
    }
    return false;
  }

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

  // ---- Settings ----

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _prefs?.setBool(_kSoundEnabled, enabled);
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    await _prefs?.setBool(_kMusicEnabled, enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    vibrationEnabled = enabled;
    await _prefs?.setBool(_kVibrationEnabled, enabled);
  }

  Future<void> setBirdSkin(int skin) async {
    birdSkin = skin;
    await _prefs?.setInt(_kBirdSkin, skin);
  }

  Future<void> setTheme(int t) async {
    theme = t;
    await _prefs?.setInt(_kTheme, t);
  }

  Future<void> setPlayerName(String name) async {
    final trimmed = name.trim();
    playerName = trimmed.isEmpty ? 'Player' : trimmed;
    await _prefs?.setString(_kPlayerName, playerName);
  }

  // ---- Coins ----

  Future<void> addCoins(int amount) async {
    if (amount == 0) return;
    coins += amount;
    if (coins < 0) coins = 0;
    await _prefs?.setInt(_kCoins, coins);
  }

  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    coins -= amount;
    await _prefs?.setInt(_kCoins, coins);
    return true;
  }

  // ---- Skins ----

  bool isSkinUnlocked(int index) => unlockedSkins.contains(index);

  int skinPrice(int index) =>
      index < skinPrices.length ? skinPrices[index] : 999;

  /// Attempts to buy a skin with coins. Returns true on success.
  Future<bool> unlockSkin(int index) async {
    if (isSkinUnlocked(index)) return true;
    final price = skinPrice(index);
    if (!await spendCoins(price)) return false;
    unlockedSkins.add(index);
    await _prefs?.setStringList(
      _kUnlockedSkins,
      unlockedSkins.map((e) => e.toString()).toList(),
    );
    return true;
  }

  // ---- Stats ----

  Future<void> _saveStats() async {
    await _prefs?.setString(_kStats, jsonEncode(stats.toJson()));
  }

  // ---- Achievements ----

  Future<void> _saveAchievements() async {
    await _prefs?.setStringList(
      _kAchievements,
      achievements.where((a) => a.unlocked).map((a) => a.id).toList(),
    );
  }

  Future<void> _unlockAchievement(String id, List<Achievement> out) async {
    final a = achievements.firstWhere((x) => x.id == id);
    if (!a.unlocked) {
      a.unlocked = true;
      await addCoins(a.reward);
      out.add(a);
    }
  }

  // ---- Mission ----

  Future<void> _saveMission() async {
    await _prefs?.setInt(_kMissionProgress, missionProgress);
    await _prefs?.setBool(_kMissionClaimed, missionClaimed);
  }

  /// Claims the daily mission reward if complete and unclaimed.
  Future<int> claimMission() async {
    if (missionComplete && !missionClaimed) {
      missionClaimed = true;
      await addCoins(missionReward);
      await _saveMission();
      return missionReward;
    }
    return 0;
  }

  /// Records the results of a finished run and returns newly unlocked
  /// achievements (for showing a toast).
  Future<List<Achievement>> recordGameResult({
    required int score,
    required int pipes,
    required int coinsCollected,
    required int bestCombo,
    required double flightSeconds,
  }) async {
    stats.gamesPlayed++;
    stats.totalPipes += pipes;
    stats.totalCoins += coinsCollected;
    stats.totalFlightSeconds += flightSeconds;
    if (bestCombo > stats.bestCombo) stats.bestCombo = bestCombo;
    await _saveStats();

    // Advance daily mission.
    switch (missionType) {
      case 'pipes':
        missionProgress += pipes;
        break;
      case 'coins':
        missionProgress += coinsCollected;
        break;
      case 'games':
        missionProgress += 1;
        break;
      case 'combo':
        if (bestCombo > missionProgress) missionProgress = bestCombo;
        break;
    }
    if (missionProgress > missionGoal) missionProgress = missionGoal;
    await _saveMission();

    // Evaluate achievements.
    final newly = <Achievement>[];
    await _unlockAchievement('first_flight', newly);
    if (score >= 10) await _unlockAchievement('score_10', newly);
    if (score >= 25) await _unlockAchievement('score_25', newly);
    if (stats.totalCoins >= 100) await _unlockAchievement('coins_100', newly);
    if (bestCombo >= 10) await _unlockAchievement('combo_10', newly);
    if (unlockedSkins.length >= skinPrices.length) {
      await _unlockAchievement('all_skins', newly);
    }
    await _saveAchievements();
    return newly;
  }
}

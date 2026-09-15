import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'game/bird_skins.dart';
import 'game/flappy_game.dart';
import 'game/themes.dart';
import 'services/audio_manager.dart';
import 'services/game_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameStorage.instance.load();
  await AudioManager.instance.init();
  runApp(const FlappyApp());
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Vappstore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = FlappyGame();
    return Scaffold(
      body: GameWidget<FlappyGame>(
        game: game,
        overlayBuilderMap: {
          'menu': (context, g) => MenuOverlay(game: g),
          'ready': (context, g) => const ReadyOverlay(),
          'hud': (context, g) => HudOverlay(game: g),
          'paused': (context, g) => PausedOverlay(game: g),
          'gameOver': (context, g) => GameOverOverlay(game: g),
        },
        initialActiveOverlays: const ['menu'],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.label,
    required this.onPressed,
    this.color = Colors.amber,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, style: const TextStyle(fontSize: 18));
    final style = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      backgroundColor: color,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: child,
          );
  }
}

/// A coin badge (🪙 count).
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins, this.fontSize = 16});
  final int coins;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: fontSize,
            height: fontSize,
            decoration: const BoxDecoration(
                color: Color(0xFFFFC107), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$coins',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main menu
// ---------------------------------------------------------------------------

class MenuOverlay extends StatefulWidget {
  const MenuOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final storage = GameStorage.instance;
    return Container(
      color: Colors.black38,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: CoinBadge(coins: storage.coins),
                  ),
                ),
                const Text('Flappy',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
                const Text('Vappstore',
                    style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                const SizedBox(height: 4),
                Text('Best: ${storage.highScore}',
                    style:
                        const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 16),
                _GameButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow,
                    onPressed: widget.game.startGame),
                const SizedBox(height: 14),

                // Daily mission card.
                _MissionCard(onChanged: _refresh),
                const SizedBox(height: 12),

                // Menu grid of feature buttons.
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _MenuChip(
                        icon: Icons.palette,
                        label: 'Shop',
                        onTap: () async {
                          await showShop(context);
                          _refresh();
                        }),
                    _MenuChip(
                        icon: Icons.wallpaper,
                        label: 'Themes',
                        onTap: () async {
                          await showThemes(context);
                          _refresh();
                        }),
                    _MenuChip(
                        icon: Icons.emoji_events,
                        label: 'Awards',
                        onTap: () => showAchievements(context)),
                    _MenuChip(
                        icon: Icons.bar_chart,
                        label: 'Stats',
                        onTap: () => showStats(context)),
                    _MenuChip(
                        icon: Icons.leaderboard,
                        label: 'Ranks',
                        onTap: () => showLeaderboard(context)),
                    _MenuChip(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          await showSettings(context);
                          _refresh();
                        }),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _editName(context),
                  icon: const Icon(Icons.person, color: Colors.white70),
                  label: Text('Name: ${storage.playerName}',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller =
        TextEditingController(text: GameStorage.instance.playerName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          maxLength: 16,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter a name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await GameStorage.instance.setPlayerName(result);
      _refresh();
    }
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Daily mission progress card on the menu.
class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final s = GameStorage.instance;
    final progress = (s.missionProgress / s.missionGoal).clamp(0.0, 1.0);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              const Text('Daily Mission',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('+${s.missionReward}🪙',
                  style: const TextStyle(color: Colors.amber, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.missionText,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${s.missionProgress}/${s.missionGoal}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              if (s.missionComplete && !s.missionClaimed)
                FilledButton(
                  onPressed: () async {
                    final r = await s.claimMission();
                    if (r > 0) onChanged();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Claim'),
                )
              else if (s.missionClaimed)
                const Text('✅ Claimed',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ready (tap to start)
// ---------------------------------------------------------------------------

class ReadyOverlay extends StatelessWidget {
  const ReadyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black12,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, color: Colors.white, size: 56),
              SizedBox(height: 8),
              Text('Tap to start',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------

class HudOverlay extends StatefulWidget {
  const HudOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CircleIconButton(
                    icon: Icons.pause, onPressed: game.pauseGame),
                // Live coin counter (rebuilds each frame via ValueListenable-ish poll).
                _LiveCoinCounter(game: game),
              ],
            ),
            const SizedBox(height: 6),
            _ActivePowerUps(game: game),
          ],
        ),
      ),
    );
  }
}

/// Polls the game for the run coin count and combo, rebuilding frequently.
class _LiveCoinCounter extends StatefulWidget {
  const _LiveCoinCounter({required this.game});
  final FlappyGame game;
  @override
  State<_LiveCoinCounter> createState() => _LiveCoinCounterState();
}

class _LiveCoinCounterState extends State<_LiveCoinCounter> {
  @override
  Widget build(BuildContext context) {
    // Rebuild on the next frame to keep the counter fresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    final g = widget.game;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CoinBadge(coins: g.coinsThisRun),
        if (g.comboMultiplier > 1) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(12)),
            child: Text('COMBO x${g.comboMultiplier}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}

/// Shows small pills for currently active power-ups.
class _ActivePowerUps extends StatelessWidget {
  const _ActivePowerUps({required this.game});
  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];
    void add(bool active, IconData icon, Color c) {
      if (active) pills.add(_pill(icon, c));
    }

    add(game.bird.hasShield, Icons.shield, const Color(0xFF29B6F6));
    add(game.isSlowMo, Icons.hourglass_bottom, const Color(0xFFAB47BC));
    add(game.isMagnet, Icons.explore, const Color(0xFFEF5350));
    add(game.isMini, Icons.compress, const Color(0xFF26A69A));
    add(game.isDoubleScore, Icons.exposure_plus_2, const Color(0xFFFFA726));

    if (pills.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(spacing: 6, children: pills),
    );
  }

  Widget _pill(IconData icon, Color c) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 16),
      );
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: IconButton(
          icon: Icon(icon, color: Colors.white), onPressed: onPressed),
    );
  }
}

// ---------------------------------------------------------------------------
// Pause + Game over
// ---------------------------------------------------------------------------

class PausedOverlay extends StatelessWidget {
  const PausedOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paused',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 24),
            _GameButton(
                label: 'RESUME',
                icon: Icons.play_arrow,
                onPressed: game.resumeGame),
            const SizedBox(height: 12),
            _GameButton(
                label: 'HOME',
                icon: Icons.home,
                color: Colors.white,
                onPressed: game.goHome),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    final medal = Medal.forScore(game.score);
    return Container(
      color: Colors.black45,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Game Over',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
                const SizedBox(height: 10),
                if (medal.name.isNotEmpty) ...[
                  Icon(Icons.military_tech, color: medal.color, size: 52),
                  Text(medal.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: medal.color)),
                  const SizedBox(height: 6),
                ],
                Text('Score: ${game.score}',
                    style:
                        const TextStyle(fontSize: 24, color: Colors.white)),
                Text('Best: ${game.highScore}',
                    style:
                        const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 6),
                CoinBadge(coins: game.coinsThisRun),
                const SizedBox(height: 2),
                Text('coins this run · best combo x${_comboMult(game.bestComboThisRun)}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white60)),
                if (game.isNewHighScore) ...[
                  const SizedBox(height: 4),
                  const Text('🎉 New Best!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                ],
                if (game.newlyUnlocked.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final a in game.newlyUnlocked)
                    Text('🏆 ${a.title}  +${a.reward}🪙',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 13)),
                ],
                const SizedBox(height: 18),
                _GameButton(
                    label: 'RETRY',
                    icon: Icons.refresh,
                    onPressed: game.startGame),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GameButton(
                        label: 'HOME',
                        icon: Icons.home,
                        color: Colors.white,
                        onPressed: game.goHome),
                    const SizedBox(width: 10),
                    _GameButton(
                      label: 'SHARE',
                      icon: Icons.share,
                      color: Colors.lightBlueAccent,
                      onPressed: () {
                        // ignore: deprecated_member_use
                        Share.share(
                          'I scored ${game.score} in Flappy Vappstore! '
                          'My best is ${game.highScore}. Can you beat me? 🐦',
                          subject: 'My Flappy Vappstore score',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _comboMult(int combo) => 1 + (combo ~/ FlappyGame.comboStep);
}

// ---------------------------------------------------------------------------
// Dialogs: shop, themes, achievements, stats, settings, leaderboard
// ---------------------------------------------------------------------------

Future<void> showShop(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _ShopDialog(),
  );
}

class _ShopDialog extends StatefulWidget {
  const _ShopDialog();
  @override
  State<_ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<_ShopDialog> {
  @override
  Widget build(BuildContext context) {
    final s = GameStorage.instance;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.palette, color: Colors.teal),
          const SizedBox(width: 8),
          const Text('Bird Shop'),
          const Spacer(),
          CoinBadge(coins: s.coins, fontSize: 14),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (int i = 0; i < BirdSkin.all.length; i++)
              _skinTile(context, i),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }

  Widget _skinTile(BuildContext context, int i) {
    final s = GameStorage.instance;
    final skin = BirdSkin.all[i];
    final unlocked = s.isSkinUnlocked(i);
    final selected = s.birdSkin == i;
    final price = s.skinPrice(i);

    return InkWell(
      onTap: () async {
        if (unlocked) {
          await s.setBirdSkin(i);
          setState(() {});
        } else {
          final ok = await s.unlockSkin(i);
          if (ok) {
            await s.setBirdSkin(i);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not enough coins')),
            );
          }
          setState(() {});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? Colors.teal : Colors.black12,
              width: selected ? 3 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: skin.body,
                  shape: BoxShape.circle,
                  border: Border.all(color: skin.outline, width: 2)),
            ),
            const SizedBox(height: 4),
            Text(skin.name, style: const TextStyle(fontSize: 11)),
            if (unlocked)
              Text(selected ? 'Selected' : 'Tap to use',
                  style: TextStyle(
                      fontSize: 10,
                      color: selected ? Colors.teal : Colors.grey))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 11, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text('$price🪙', style: const TextStyle(fontSize: 10)),
                ],
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

Future<void> showThemes(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _ThemesDialog(),
  );
}

class _ThemesDialog extends StatefulWidget {
  const _ThemesDialog();
  @override
  State<_ThemesDialog> createState() => _ThemesDialogState();
}

class _ThemesDialogState extends State<_ThemesDialog> {
  @override
  Widget build(BuildContext context) {
    final s = GameStorage.instance;
    return AlertDialog(
      title: const Text('Themes'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < GameTheme.all.length; i++)
              ListTile(
                dense: true,
                onTap: () async {
                  await s.setTheme(i);
                  setState(() {});
                },
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _swatch(GameTheme.all[i].dayTop),
                    _swatch(GameTheme.all[i].pipeBody),
                  ],
                ),
                title: Text(GameTheme.all[i].name),
                trailing: s.theme == i
                    ? const Icon(Icons.check_circle, color: Colors.teal)
                    : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }

  Widget _swatch(Color c) => Container(
        margin: const EdgeInsets.only(right: 4),
        width: 18,
        height: 18,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
      );
}

void showAchievements(BuildContext context) {
  final list = GameStorage.instance.achievements;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.emoji_events, color: Colors.amber),
        SizedBox(width: 8),
        Text('Achievements'),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in list)
              ListTile(
                dense: true,
                leading: Icon(
                    a.unlocked ? Icons.check_circle : Icons.lock_outline,
                    color: a.unlocked ? Colors.green : Colors.grey),
                title: Text(a.title),
                subtitle: Text(a.description),
                trailing: Text('+${a.reward}🪙',
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

void showStats(BuildContext context) {
  final s = GameStorage.instance.stats;
  String fmtTime(double sec) {
    final m = sec ~/ 60;
    final r = (sec % 60).toStringAsFixed(0);
    return m > 0 ? '${m}m ${r}s' : '${r}s';
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.bar_chart, color: Colors.teal),
        SizedBox(width: 8),
        Text('Statistics'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statRow('Games played', '${s.gamesPlayed}'),
          _statRow('Pipes passed', '${s.totalPipes}'),
          _statRow('Coins collected', '${s.totalCoins}'),
          _statRow('Best combo', 'x${1 + s.bestCombo ~/ FlappyGame.comboStep}'),
          _statRow('Total flight time', fmtTime(s.totalFlightSeconds)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

Widget _statRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );

Future<void> showSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();
  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final s = GameStorage.instance;
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Sound effects'),
            secondary: const Icon(Icons.volume_up),
            value: s.soundEnabled,
            onChanged: (v) async {
              await s.setSoundEnabled(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Music'),
            secondary: const Icon(Icons.music_note),
            value: s.musicEnabled,
            onChanged: (v) async {
              await s.setMusicEnabled(v);
              await AudioManager.instance.refreshMusicPreference();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            secondary: const Icon(Icons.vibration),
            value: s.vibrationEnabled,
            onChanged: (v) async {
              await s.setVibrationEnabled(v);
              setState(() {});
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done')),
      ],
    );
  }
}

void showLeaderboard(BuildContext context) {
  final entries = GameStorage.instance.leaderboard;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.leaderboard, color: Colors.amber),
        SizedBox(width: 8),
        Text('Top 5'),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: entries.isEmpty
            ? const Text('No scores yet. Play a round!')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < entries.length; i++)
                    ListTile(
                      dense: true,
                      leading: Text('#${i + 1}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(entries[i].name),
                      trailing: Text('${entries[i].score}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

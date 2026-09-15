import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'game/bird_skins.dart';
import 'game/flappy_game.dart';
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
      theme: ThemeData(useMaterial3: true),
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
          'hud': (context, g) => HudOverlay(game: g),
          'paused': (context, g) => PausedOverlay(game: g),
          'gameOver': (context, g) => GameOverOverlay(game: g),
        },
        initialActiveOverlays: const ['menu'],
      ),
    );
  }
}

/// Reusable primary game button.
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
    final child = Text(label, style: const TextStyle(fontSize: 20));
    final style = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      backgroundColor: color,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: child,
          );
  }
}

/// Main menu with title, play button, skin picker and sound/music toggles.
class MenuOverlay extends StatefulWidget {
  const MenuOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
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
                const SizedBox(height: 8),
                const Text(
                  'Flappy',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
                const Text(
                  'Vappstore',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Best: ${storage.highScore}',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 16),

                // Skin picker.
                const Text('Choose your bird',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 6),
                _SkinPicker(onChanged: () => setState(() {})),
                const SizedBox(height: 16),

                _GameButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow,
                  onPressed: widget.game.startGame,
                ),
                const SizedBox(height: 10),

                // Sound + music toggles.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleChip(
                      icon: storage.soundEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      label: 'SFX',
                      value: storage.soundEnabled,
                      onTap: () async {
                        await storage.setSoundEnabled(!storage.soundEnabled);
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 10),
                    _ToggleChip(
                      icon: storage.musicEnabled
                          ? Icons.music_note
                          : Icons.music_off,
                      label: 'Music',
                      value: storage.musicEnabled,
                      onTap: () async {
                        await storage.setMusicEnabled(!storage.musicEnabled);
                        await AudioManager.instance.refreshMusicPreference();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name + leaderboard.
                TextButton.icon(
                  onPressed: () => _editName(context),
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: Text('Name: ${storage.playerName}',
                      style: const TextStyle(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () => showLeaderboard(context),
                  icon: const Icon(Icons.leaderboard, color: Colors.white),
                  label: const Text('Leaderboard',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await GameStorage.instance.setPlayerName(result);
      setState(() {});
    }
  }
}

/// Horizontal list of selectable bird colours.
class _SkinPicker extends StatelessWidget {
  const _SkinPicker({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = GameStorage.instance.birdSkin;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: BirdSkin.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final skin = BirdSkin.all[i];
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () async {
              await GameStorage.instance.setBirdSkin(i);
              onChanged();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: skin.body,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : skin.outline,
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: isSelected
                    ? [const BoxShadow(color: Colors.black45, blurRadius: 6)]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value ? Colors.amber : Colors.black38,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: value ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: value ? Colors.black : Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// In-game HUD: pause + sound buttons.
class HudOverlay extends StatefulWidget {
  const HudOverlay({super.key, required this.game});
  final FlappyGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircleIconButton(
                icon: Icons.pause, onPressed: widget.game.pauseGame),
            _CircleIconButton(
              icon: GameStorage.instance.soundEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
              onPressed: () async {
                await GameStorage.instance
                    .setSoundEnabled(!GameStorage.instance.soundEnabled);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
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
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/// Pause screen with resume + home.
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
            const Text(
              'Paused',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
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
              onPressed: game.goHome,
            ),
          ],
        ),
      ),
    );
  }
}

/// Game-over screen with medal, leaderboard status, share and home.
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
                const Text(
                  'Game Over',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 12),
                if (medal.name.isNotEmpty) ...[
                  Icon(Icons.military_tech, color: medal.color, size: 56),
                  Text(medal.name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: medal.color)),
                  const SizedBox(height: 8),
                ],
                Text('Score: ${game.score}',
                    style:
                        const TextStyle(fontSize: 26, color: Colors.white)),
                Text('Best: ${game.highScore}',
                    style:
                        const TextStyle(fontSize: 18, color: Colors.white70)),
                if (game.isNewHighScore) ...[
                  const SizedBox(height: 4),
                  const Text('🎉 New Best!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                ] else if (game.madeLeaderboard) ...[
                  const SizedBox(height: 4),
                  const Text('⭐ Top 5!',
                      style: TextStyle(fontSize: 16, color: Colors.amber)),
                ],
                const SizedBox(height: 20),
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
                      onPressed: game.goHome,
                    ),
                    const SizedBox(width: 10),
                    _GameButton(
                      label: 'SHARE',
                      icon: Icons.share,
                      color: Colors.lightBlueAccent,
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'I scored ${game.score} in Flappy '
                                'Vappstore! My best is ${game.highScore}. '
                                'Can you beat me? 🐦',
                            subject: 'My Flappy Vappstore score',
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => showLeaderboard(context),
                  icon: const Icon(Icons.leaderboard, color: Colors.white),
                  label: const Text('Leaderboard',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the local top-5 leaderboard in a dialog.
void showLeaderboard(BuildContext context) {
  final entries = GameStorage.instance.leaderboard;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.leaderboard, color: Colors.amber),
          SizedBox(width: 8),
          Text('Top 5'),
        ],
      ),
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
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

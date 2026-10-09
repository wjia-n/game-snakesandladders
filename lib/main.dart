import 'package:flutter/material.dart';
import 'audio.dart';
import 'game_screen.dart';
import 'settings.dart';
import 'settings_screen.dart';
import 'snakes_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SlAudio.instance.init();
  await SlSettings.instance.init();
  runApp(const SnakesLaddersApp());
}

class SnakesLaddersApp extends StatelessWidget {
  const SnakesLaddersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snakes and Ladders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: StTheme.parchment,
        fontFamily: StTheme.bodyFamily,
      ),
      home: const MainMenu(),
    );
  }
}

/// Main menu: parchment full-bleed, painted title, wooden tray of pawns for
/// the player-count selector, carved-wood PLAY button, brass settings cog.
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with WidgetsBindingObserver {
  int _playerCount = 2;
  int _humans = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SlAudio.instance.playMusic('audio/music_menu.wav');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) SlAudio.instance.stopMusic();
    if (state == AppLifecycleState.resumed && mounted) {
      SlAudio.instance.playMusic('audio/music_menu.wav');
    }
  }

  void _play() {
    SlAudio.instance.click();
    SlAudio.instance.playMusic('audio/music_game.wav');
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SnakesGameScreen(
              config: GameConfig(playerCount: _playerCount, humans: _humans),
            ),
          ),
        )
        .then((_) {
      if (mounted) SlAudio.instance.playMusic('audio/music_menu.wav');
    });
  }

  void _openSettings() {
    SlAudio.instance.click();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final wins = SlSettings.instance.wins;
    final crowns = [for (int i = 0; i < 4; i++) '${StTheme.pawnNames[i].split(' ').last} ${wins[i]}'].join('  •  ');
    return Scaffold(
      body: ParchmentBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: BrassRoundButton(icon: Icons.settings, onTap: _openSettings),
                ),
                const SizedBox(height: 6),
                // decorative pawn parade
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: WoodenPawn(color: StTheme.pawnColors[i], size: 34),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Snakes & Ladders', style: StTheme.title, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Virtues Ascend • Vices Descend',
                    style: StTheme.caption.copyWith(fontSize: 14)),
                const SizedBox(height: 26),
                // player-count tray
                Text('Players at the Table', style: StTheme.titleSmall.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                WoodPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int c = 2; c <= 4; c++)
                        GestureDetector(
                          onTap: () {
                            SlAudio.instance.click();
                            setState(() {
                              _playerCount = c;
                              _humans = _humans.clamp(1, c);
                            });
                          },
                          child: Column(
                            children: [
                              Opacity(
                                opacity: _playerCount == c ? 1.0 : 0.35,
                                child: Row(
                                  children: [
                                    for (int i = 0; i < c; i++)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: WoodenPawn(color: StTheme.pawnColors[i], size: 20),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('$c',
                                  style: StTheme.body.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: _playerCount == c ? StTheme.goldLeaf : StTheme.parchmentDeep)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // human seats
                Text('Human Players', style: StTheme.titleSmall.copyWith(fontSize: 22)),
                Text('the rest play as clockwork rivals',
                    style: StTheme.caption.copyWith(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int h = 1; h <= _playerCount; h++)
                      GestureDetector(
                        onTap: () {
                          SlAudio.instance.click();
                          setState(() => _humans = h);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _humans == h
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFD9B45C), StTheme.brass, Color(0xFF8A6B2A)],
                                  )
                                : null,
                            color: _humans == h ? null : StTheme.parchmentDeep,
                            border: Border.all(color: StTheme.brass, width: 2),
                            boxShadow: StTheme.brassShadow,
                          ),
                          alignment: Alignment.center,
                          child: Text('$h',
                              style: StTheme.titleSmall.copyWith(
                                  fontSize: 20,
                                  color: _humans == h ? StTheme.inkBrown : StTheme.inkSoft)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                WoodButton(label: 'PLAY', onTap: _play),
                const SizedBox(height: 18),
                // how to play card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: StTheme.parchmentDeep.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: StTheme.brass.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: Text(
                    'Cast the die and climb from square 1 to 100. Ladders lift you, '
                    'serpents slide you down. Land exactly on 100 to win — '
                    'a six grants another cast.',
                    style: StTheme.body.copyWith(fontSize: 13.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Parlour records — $crowns', style: StTheme.caption, textAlign: TextAlign.center),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

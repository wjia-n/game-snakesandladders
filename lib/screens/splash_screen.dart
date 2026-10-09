import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/storybook_themes.dart';
import '../theme/storybook_ui.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company moment → game splash (logo + name +
/// animated loading line + "Credits: WAJIHA").
class SplashScreen extends StatefulWidget {
  final StoryAudio audio;
  final StorySettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _showGame = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splashes show, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Company splash moment.
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _showGame = true);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StoryThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF14100B),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showGame
            ? _GameSplash(theme: theme, loader: _loader)
            : const _CompanySplash(),
      ),
    );
  }
}

/// Company splash: the official WAJIHA winged-W mark, untouched.
class _CompanySplash extends StatelessWidget {
  const _CompanySplash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/wajiha_logo.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          const Text(
            'W A J I H A',
            style: TextStyle(
              fontFamily: Story.displayFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
              color: Color(0xFFD4A93C),
            ),
          ),
        ],
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final StoryThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return ParchmentBackdrop(
      t: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    offset: Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/sl_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Snakes & Ladders',
                style: Story.title(44, t: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'VIRTUES ASCEND • VICES DESCEND',
              style: Story.label(12, t: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.18),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1
                          ? 'Unrolling the board…'
                          : 'Ready!',
                      style: Story.body(13,
                          t: theme,
                          color: theme.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Story.label(14, t: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

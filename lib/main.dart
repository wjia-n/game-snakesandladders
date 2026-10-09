import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/storybook_themes.dart';
import 'theme/storybook_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = StorySettings();
  await settings.load();
  final audio = StoryAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(SnakesApp(settings: settings, audio: audio));
}

class SnakesApp extends StatefulWidget {
  final StorySettings settings;
  final StoryAudio audio;
  const SnakesApp({super.key, required this.settings, required this.audio});

  @override
  State<SnakesApp> createState() => _SnakesAppState();
}

class _SnakesAppState extends State<SnakesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Snakes & Ladders',
        debugShowCheckedModeBanner: false,
        theme: _storyTheme(widget.settings),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}

ThemeData _storyTheme(StorySettings settings) {
  final t = StoryThemes.byId(settings.themeId, custom: settings.customTheme);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: t.parchment,
    fontFamily: Story.bodyFamily,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: t.accent,
      onPrimary: t.parchment,
      secondary: t.accentLight,
      onSecondary: t.ink,
      surface: t.parchment,
      onSurface: t.ink,
      error: const Color(0xFFA93226),
      onError: t.parchment,
    ),
    textTheme: TextTheme(
      displayLarge: Story.title(34, t: t),
      displayMedium: Story.title(26, t: t),
      titleLarge: Story.titleSmall(22, t: t),
      bodyLarge: Story.body(16, t: t),
      bodyMedium: Story.body(14, t: t),
      labelLarge: Story.label(14, t: t),
    ),
    dialogTheme: DialogThemeData(backgroundColor: t.parchment),
  );
}

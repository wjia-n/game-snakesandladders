import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/storybook_themes.dart';
import '../theme/storybook_ui.dart';
import 'pro_screen.dart';

/// Settings — storybook edition: sound, PRO, appearance, credits.
class SettingsScreen extends StatefulWidget {
  final StoryAudio audio;
  final StorySettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StoreService _store = StoreService();

  StoryThemeDef get _t => StoryThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
    _store.proPurchased.addListener(_onPro);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Story.body(15, t: _t)),
        backgroundColor: _t.woodDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
    }
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final audio = widget.audio;
    return ParchmentBackdrop(
      t: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.ink),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Story.titleSmall(22, t: t)),
          centerTitle: true,
        ),
        body: ListenableBuilder(
          listenable: s,
          builder: (_, _) => SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Sound', t),
                SettingRow(
                  t: t,
                  label: 'Music',
                  control: StoryToggle(
                    t: t,
                    value: s.musicOn,
                    onChanged: (v) async {
                      audio.click();
                      await s.setMusic(v);
                      audio.configure(
                          musicOn: s.musicOn,
                          sfxOn: s.sfxOn,
                          volume: s.volume);
                      if (v) {
                        audio.startMenuMusic();
                      } else {
                        audio.stopMusic();
                      }
                    },
                  ),
                ),
                SettingRow(
                  t: t,
                  label: 'Sound effects',
                  control: StoryToggle(
                    t: t,
                    value: s.sfxOn,
                    onChanged: (v) async {
                      await s.setSfx(v);
                      audio.configure(
                          musicOn: s.musicOn,
                          sfxOn: s.sfxOn,
                          volume: s.volume);
                      if (v) audio.click();
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text('Volume', style: Story.body(16, t: t)),
                StorySlider(
                  t: t,
                  value: s.volume,
                  onChanged: (v) async {
                    await s.setVolume(v);
                    audio.configure(
                        musicOn: s.musicOn,
                        sfxOn: s.sfxOn,
                        volume: s.volume);
                  },
                ),
                const SizedBox(height: 10),
                _SectionTitle('Snakes & Ladders PRO', t),
                SettingRow(
                  t: t,
                  label: s.isPro ? 'PRO active ✦' : 'Unlock PRO',
                  control: GestureDetector(
                    onTap: () {
                      audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: audio,
                          settings: s,
                          store: _store,
                        ),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: s.isPro
                            ? t.accent.withValues(alpha: 0.85)
                            : t.parchmentDeep.withValues(alpha: 0.6),
                        border: Border.all(
                            color: t.accentLight, width: 2),
                      ),
                      child: Text(
                        s.isPro ? '✦ PRO' : 'View',
                        style: Story.label(13,
                            t: t,
                            color: s.isPro ? t.ink : t.inkSoft),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _SectionTitle('Appearance', t),
                SettingRow(
                  t: t,
                  label: 'Theme',
                  control: Text(
                    StoryThemes.byId(s.themeId, custom: s.customTheme).name,
                    style: Story.label(14, t: t),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final th in StoryThemes.all)
                      GestureDetector(
                        onTap: () async {
                          audio.click();
                          final locked = StoryThemes.isProTheme(th.id) &&
                              !s.isPro;
                          if (locked) {
                            await Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (_) => ProScreen(
                                audio: audio,
                                settings: s,
                                store: _store,
                              ),
                            ));
                            return;
                          }
                          s.setTheme(th.id);
                        },
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: th.parchment,
                            border: Border.all(
                              color: s.themeId == th.id
                                  ? th.accentLight
                                  : th.accent.withValues(alpha: 0.35),
                              width: s.themeId == th.id ? 3 : 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final c in th.pawnColors)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (StoryThemes.isProTheme(th.id) &&
                                  !s.isPro)
                                Icon(Icons.lock,
                                    size: 12, color: th.inkSoft),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SettingRow(
                  t: t,
                  label: 'Token style',
                  control: Text(
                    TokenShapes.names[s.tokenShape],
                    style: Story.label(14, t: t),
                  ),
                ),
                SettingRow(
                  t: t,
                  label: 'Dice style',
                  control: Text(
                    DiceStyles.names[s.diceStyle],
                    style: Story.label(14, t: t),
                  ),
                ),
                const SizedBox(height: 10),
                _SectionTitle('Tales told', t),
                SettingRow(
                  t: t,
                  label: 'Games played',
                  control: Text('${s.gamesPlayed}',
                      style: Story.label(14, t: t)),
                ),
                SettingRow(
                  t: t,
                  label: 'Wins',
                  control:
                      Text('${s.wins}', style: Story.label(14, t: t)),
                ),
                if (s.biggestClimb > 0)
                  SettingRow(
                    t: t,
                    label: 'Biggest climb',
                    control: Text('${s.biggestClimb} squares',
                        style: Story.label(14, t: t)),
                  ),
                if (s.longestSlide > 0)
                  SettingRow(
                    t: t,
                    label: 'Longest slide',
                    control: Text('${s.longestSlide} squares',
                        style: Story.label(14, t: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Story.label(12, t: t)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final StoryThemeDef t;
  const _SectionTitle(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: Story.titleSmall(18, t: t)),
    );
  }
}

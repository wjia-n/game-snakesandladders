import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../engine/sl_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/storybook_themes.dart';
import '../theme/storybook_ui.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — vintage storybook edition.
/// Logo, PLAY, mode setup (players / bots / difficulty), theme picker,
/// player renaming, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final StoryAudio audio;
  final StorySettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  StorySettings get _s => widget.settings;
  StoryThemeDef get _t => StoryThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
    _store.proPurchased.addListener(_onPro);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
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
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  void _play() {
    widget.audio.gameStart();
    final colors = _t.pawnColors;
    final players = [
      for (int i = 0; i < _s.playerCount; i++)
        SlPlayer(
          name: _s.playerNames[i],
          colorIndex: i,
          isBot: _s.botSeats.contains(i),
        ),
    ];
    assert(colors.length >= _s.playerCount);
    final engine = SlEngine(
      players: players,
      botDifficulty: BotDifficulty.values[_s.difficulty],
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ParchmentBackdrop(
      t: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: Story.paperShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        Image.asset('assets/sl_logo.png', fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Snakes & Ladders',
                      style: Story.title(40, t: t),
                      textAlign: TextAlign.center),
                  Text(
                    'VIRTUES ASCEND • VICES DESCEND',
                    style: Story.label(12, t: t),
                  ),
                  const SizedBox(height: 22),
                  WoodButton(label: '▶  Play', onTap: _play, t: t, width: 260),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: widget.audio,
                          settings: _s,
                          store: _store,
                        ),
                      ));
                    },
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          t.accent.withValues(alpha: 0.9),
                          t.accentDark,
                        ]),
                        border: Border.all(
                            color: t.accentLight, width: 2.5),
                        boxShadow: Story.paperShadow,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _s.isPro ? '✦  PRO ACTIVE' : '✦  Get PRO',
                        style: Story.label(17, t: t, color: t.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Wins: ${_s.wins}   •   Games: ${_s.gamesPlayed}${_s.biggestClimb > 0 ? '   •   Best climb: ${_s.biggestClimb}' : ''}',
                      style: Story.label(12, t: t),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Story.label(12, t: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, StoryThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: t.parchment,
            border: Border.all(color: t.accent, width: 3),
            boxShadow: Story.paperShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play',
                    style: Story.titleSmall(24, t: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• Cast the die and climb from square 1 to 100.',
                  '• Land on a ladder foot to climb up.',
                  '• Land on a serpent\'s head to slide down.',
                  '• Land EXACTLY on 100 to win — overshooting stays put.',
                  '• Rolling a 6 grants another cast.',
                  '• Climb ladder 80 to win instantly!',
                  '• Every side has its own die — tap yours on your turn.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: Story.body(14, t: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: WoodButton(
                    label: 'Got it!',
                    width: 180,
                    fontSize: 16,
                    t: t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final StoryThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.accentLight, theme.accent, theme.accentDark],
              ),
              border: Border.all(color: theme.accentDark, width: 2),
              boxShadow: Story.paperShadow,
            ),
            child: Icon(icon, color: theme.ink, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: Story.label(12, t: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Mode setup: player count, per-seat human/bot, bot difficulty.
class _ModeCard extends StatelessWidget {
  final StoryThemeDef theme;
  const _ModeCard({required this.theme});

  static const difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    return _Card(
      theme: theme,
      title: 'Game Mode',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Players:', style: Story.body(15, t: theme)),
              const SizedBox(width: 12),
              for (final c in [2, 3, 4])
                _Chip(
                  theme: theme,
                  label: '$c',
                  selected: s.playerCount == c,
                  onTap: () {
                    audio.click();
                    final bots = s.botSeats.where((b) => b < c).toList();
                    s.setSetup(
                        players: c, botSeats: bots, difficulty: s.difficulty);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < s.playerCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  TokenPawn(
                      color: theme.pawnColors[i],
                      size: 18,
                      shape: s.tokenShape),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.playerNames[i],
                      style: Story.body(15, t: theme),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _Chip(
                    theme: theme,
                    label: 'Human',
                    selected: !s.botSeats.contains(i),
                    onTap: () {
                      audio.click();
                      final bots = [...s.botSeats]..remove(i);
                      s.setSetup(
                          players: s.playerCount,
                          botSeats: bots,
                          difficulty: s.difficulty);
                    },
                  ),
                  const SizedBox(width: 6),
                  _Chip(
                    theme: theme,
                    label: 'Bot',
                    selected: s.botSeats.contains(i),
                    onTap: () {
                      audio.click();
                      final bots = {...s.botSeats, i}.toList();
                      s.setSetup(
                          players: s.playerCount,
                          botSeats: bots,
                          difficulty: s.difficulty);
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Mode:', style: Story.body(15, t: theme)),
              const SizedBox(width: 12),
              for (int d = 0; d < 3; d++)
                _Chip(
                  theme: theme,
                  label:
                      '${d == 2 && !s.isPro ? '🔒 ' : ''}${difficulties[d]}',
                  selected: s.difficulty == d,
                  onTap: () async {
                    audio.click();
                    if (d == 2 && !s.isPro) {
                      await Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: audio,
                          settings: s,
                          store: screen._store,
                        ),
                      ));
                      return;
                    }
                    s.setSetup(
                        players: s.playerCount,
                        botSeats: s.botSeats,
                        difficulty: d);
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Clockwork rivals roll and climb just like you — watch their dice!',
              style: Story.caption(12, t: theme),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Theme / appearance picker: 13 themes + custom creator, 12 token shapes,
/// 6 dice styles — with PRO locks.
class _ThemeCard extends StatelessWidget {
  final StoryThemeDef theme;
  const _ThemeCard({required this.theme});

  Future<void> _goPro(BuildContext context, _MenuScreenState screen) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: screen.widget.audio,
        settings: screen._s,
        store: screen._store,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    final isPro = s.isPro;
    return _Card(
      theme: theme,
      title: 'Storybook Style',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final th in StoryThemes.all)
                _ThemeTile(
                  theme: theme,
                  th: th,
                  selected: s.themeId == th.id,
                  locked:
                      StoryThemes.isProTheme(th.id) && !isPro,
                  onTap: () {
                    audio.click();
                    if (StoryThemes.isProTheme(th.id) && !isPro) {
                      _goPro(context, screen);
                      return;
                    }
                    s.setTheme(th.id);
                  },
                ),
              // Custom theme tile (PRO).
              _ThemeTile(
                theme: theme,
                th: s.customTheme,
                selected: s.themeId == 'custom',
                locked: !isPro,
                custom: true,
                onTap: () {
                  audio.click();
                  if (!isPro) {
                    _goPro(context, screen);
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: audio,
                      settings: s,
                    ),
                  ));
                },
              ),
            ],
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🔒 ${StoryThemes.all.length - StoryThemes.freeThemeIds.length} more tales in PRO',
                style: Story.label(12, t: theme),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child:
                Text('Token style:', style: Story.body(15, t: theme)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < TokenShapes.names.length; i++)
                _Chip(
                  theme: theme,
                  label:
                      '${TokenShapes.isPro(i) && !isPro ? '🔒 ' : ''}${TokenShapes.names[i]}',
                  selected: s.tokenShape == i,
                  onTap: () {
                    audio.click();
                    if (TokenShapes.isPro(i) && !isPro) {
                      _goPro(context, screen);
                      return;
                    }
                    s.setTokenShape(i);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Dice style:', style: Story.body(15, t: theme)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < DiceStyles.names.length; i++)
                _Chip(
                  theme: theme,
                  label:
                      '${DiceStyles.isPro(i) && !isPro ? '🔒 ' : ''}${DiceStyles.names[i]}',
                  selected: s.diceStyle == i,
                  onTap: () {
                    audio.click();
                    if (DiceStyles.isPro(i) && !isPro) {
                      _goPro(context, screen);
                      return;
                    }
                    s.setDiceStyle(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final StoryThemeDef theme;
  final StoryThemeDef th;
  final bool selected;
  final bool locked;
  final bool custom;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.theme,
    required this.th,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: th.parchment,
              border: Border.all(
                color: selected
                    ? th.accentLight
                    : th.accent.withValues(alpha: 0.35),
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in th.pawnColors)
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                              color: th.accentLight, width: 1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  custom ? '🎨 My Creation' : th.name,
                  style: Story.label(10, t: th),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (locked)
            Container(
              width: 96,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: 0.55),
              ),
              child: Icon(Icons.lock,
                  color: theme.accentLight, size: 22),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Rename the four player slots.
class _NamesCard extends StatelessWidget {
  final StoryThemeDef theme;
  const _NamesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    return _Card(
      theme: theme,
      title: 'Player Names',
      child: Column(
        children: [
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  TokenPawn(
                      color: theme.pawnColors[i],
                      size: 20,
                      shape: s.tokenShape),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NameField(
                      theme: theme,
                      index: i,
                      initial: s.playerNames[i],
                      onDone: (v) => s.setPlayerName(i, v),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Names show on dice trays, turn plaques and the winner podium.',
            style: Story.caption(12, t: theme),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final StoryThemeDef theme;
  final int index;
  final String initial;
  final ValueChanged<String> onDone;
  const _NameField(
      {required this.theme,
      required this.index,
      required this.initial,
      required this.onDone});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _f;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _f = FocusNode(debugLabel: 'name${widget.index}');
    _f.addListener(_onFocusChange);
  }

  /// Commit on focus loss: tapping another field or scrolling away must not
  /// silently drop a rename (keyboard-done alone is not enough).
  void _onFocusChange() {
    if (!_f.hasFocus) widget.onDone(_c.text);
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _f.removeListener(_onFocusChange);
    _f.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: widget.theme.parchmentDeep.withValues(alpha: 0.5),
        border:
            Border.all(color: widget.theme.accent.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: _c,
        focusNode: _f,
        style: Story.body(15, t: widget.theme),
        maxLength: 16,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'Player ${widget.index + 1}',
          hintStyle: Story.body(14,
              t: widget.theme,
              color: widget.theme.inkSoft.withValues(alpha: 0.6)),
        ),
        onChanged: widget.onDone, // save-on-keystroke: never lose a rename
        onSubmitted: widget.onDone,
        onEditingComplete: () => widget.onDone(_c.text),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Tip jar (IAP).
class _SupportCard extends StatelessWidget {
  final StoryThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final audio = screen.widget.audio;
    return _Card(
      theme: theme,
      title: 'Support Wajiha',
      child: Column(
        children: [
          Text(
            'Snakes & Ladders is 100% free. If it made you smile, a small tip keeps the storybook open!',
            style: Story.body(14, t: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final tips = [
              store.coffeeProduct,
              store.chocolateProduct,
            ].whereType<ProductDetails>().toList();
            if (!store.storeReady) {
              return Text(
                store.error ?? 'Loading…',
                style: Story.body(13,
                    t: theme,
                    color: theme.inkSoft.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              );
            }
            if (tips.isEmpty) {
              return Text('Tips coming soon.',
                  style: Story.body(13,
                      t: theme,
                      color: theme.inkSoft.withValues(alpha: 0.8)));
            }
            return Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _Chip(
                    theme: theme,
                    label: p.id == StoreService.chocolateId
                        ? '🍫 ${p.price}'
                        : '☕ ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  final StoryThemeDef theme;
  final String title;
  final Widget child;
  const _Card(
      {required this.theme, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.parchment.withValues(alpha: 0.75),
        border: Border.all(color: theme.accent, width: 2),
        boxShadow: Story.paperShadow,
      ),
      child: Column(
        children: [
          Text(title, style: Story.titleSmall(20, t: theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final StoryThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? theme.accent.withValues(alpha: 0.85)
              : theme.parchmentDeep.withValues(alpha: 0.6),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: Story.label(13,
              t: theme, color: selected ? theme.ink : theme.inkSoft),
        ),
      ),
    );
  }
}

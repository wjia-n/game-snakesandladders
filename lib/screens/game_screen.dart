import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/sl_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/storybook_themes.dart';
import '../theme/storybook_ui.dart';
import 'settings_screen.dart';

/// Snakes & Ladders game screen — storybook exemplar edition.
///
/// - Every player side has its OWN dice: it activates and rolls with a
///   real-time animation on the current player's card (human or bot).
/// - Token moves animate square-by-square with hops; ladders climb and
///   snakes slide along painted paths. Bot turns are fully visible.
/// - The engine owns the turn state machine, so the UI can never desync.
class GameScreen extends StatefulWidget {
  final SlEngine engine;
  final StoryAudio audio;
  final StorySettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _travelCtrl;
  SlTravel? _shownTravel;
  int _segIdx = -1;
  bool _paused = false;
  bool _overHandled = false;
  int _maxClimb = 0;
  int _maxSlide = 0;

  SlEngine get _e => widget.engine;
  StoryThemeDef get _t => StoryThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _travelCtrl = AnimationController(vsync: this);
    _e.onEvent = _onEngineEvent;
    _e.addListener(_onEngineChanged);
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _travelCtrl.dispose();
    _e.removeListener(_onEngineChanged);
    _e.onEvent = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
      if (!_e.over && mounted) {
        setState(() {
          _paused = true;
          _e.setPaused(true);
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _onEngineChanged() {
    if (!mounted) return;
    // Drive the travel-animation controller from the engine's SlTravel.
    final travel = _e.travel;
    if (travel != null && !identical(travel, _shownTravel)) {
      _shownTravel = travel;
      _segIdx = -1;
      for (final h in travel.move.climbs) {
        _maxClimb = max(_maxClimb, h.delta);
      }
      for (final h in travel.move.slides) {
        _maxSlide = max(_maxSlide, h.delta);
      }
      _travelCtrl.duration = Duration(milliseconds: travel.totalMs);
      _travelCtrl.forward(from: 0);
    } else if (travel == null) {
      _shownTravel = null;
    }
    setState(() {});
    if (_e.over && !_overHandled) _onGameOver();
  }

  Future<void> _onEngineEvent(SlEvent event) async {
    final a = widget.audio;
    switch (event) {
      case SlEvent.rollOffTick:
      case SlEvent.diceRolling:
        await a.dice();
        break;
      case SlEvent.rollOffDone:
      case SlEvent.extraRoll:
        await a.click();
        break;
      case SlEvent.moveSettled:
        break; // segment sounds are driven by the travel animation
      case SlEvent.overshoot:
      case SlEvent.invalid:
        await a.invalid();
        break;
      case SlEvent.humanWon:
        await a.win();
        break;
      case SlEvent.botWon:
        await a.lose();
        break;
    }
  }

  /// Plays hop / ladder / snake sounds as the travel animation enters each
  /// new segment. Purely presentational — the engine owns the timing.
  void _segSound(int idx, SlSeg seg) {
    if (idx == _segIdx) return;
    _segIdx = idx;
    if ((seg.to - seg.from).abs() < 0.01) return; // pause segment
    if (seg.isSnake) {
      widget.audio.snake();
    } else if (seg.isClimb) {
      widget.audio.ladder();
    } else {
      widget.audio.hop();
    }
  }

  Future<void> _onGameOver() async {
    _overHandled = true;
    final w = _e.players[_e.winner!];
    final humanWon = !w.isBot;
    await widget.settings.recordGame(
      humanWon: humanWon,
      biggestClimb: _maxClimb,
      longestSlide: _maxSlide,
    );
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinnerDialog(
        engine: _e,
        theme: _t,
        audio: widget.audio,
        settings: widget.settings,
        humanWon: humanWon,
      ),
    );
    if (!mounted) return;
    if (again == true) {
      _overHandled = false;
      _maxClimb = 0;
      _maxSlide = 0;
      _e.restart();
      widget.audio.startGameMusic();
    } else {
      // App-scoped music keeps playing; menu switches back to menu track.
      Navigator.of(context).pop();
    }
  }

  void _onDiceTap(int pi) {
    if (_paused || _e.over) return;
    if (_e.awaitingRoll && _e.turn == pi && !_e.current.isBot) {
      widget.audio.click();
      _e.roll();
    }
  }

  void _togglePause() {
    if (_e.over) return;
    widget.audio.click();
    setState(() {
      _paused = !_paused;
      _e.setPaused(_paused);
      if (_paused) {
        widget.audio.onAppPaused();
      } else {
        widget.audio.onAppResumed();
      }
    });
  }

  // ------------------------------------------------------------ geometry
  /// Center of square n (1..100) in a boardW×boardW board, boustrophedon.
  static Offset cellCenter(int n, double boardW) {
    final cell = boardW / 10;
    final r0 = (n - 1) ~/ 10; // 0 = bottom row
    final pr = (n - 1) % 10;
    final col = r0.isEven ? pr : 9 - pr;
    final row = 9 - r0;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  /// Bench slot center for player i (off-board pawns wait here).
  Offset _benchSlot(int i, double boardW, double benchTop) {
    return Offset(boardW * (i + 0.5) / _e.n, benchTop + 21);
  }

  Offset _pointAt(double sq, double boardW, double benchTop) => sq < 0.5
      ? _benchSlot(_e.travel!.pi, boardW, benchTop)
      : cellCenter(sq.round().clamp(1, 100), boardW);

  /// Pawn position for the traveling pawn at travel progress p.
  Offset _travelPoint(SlTravel t, double p, double boardW, double benchTop) {
    final loc = t.locate(p);
    final seg = loc.seg;
    final cell = boardW / 10;
    if (seg.isSnake) {
      return snakePathPoint(
          _pointAt(seg.from, boardW, benchTop),
          _pointAt(seg.to, boardW, benchTop),
          loc.frac);
    }
    if (seg.isClimb) {
      final a = _pointAt(seg.from, boardW, benchTop);
      final b = _pointAt(seg.to, boardW, benchTop);
      final arc = sin(pi * loc.frac) * cell * 0.9;
      return Offset.lerp(a, b, loc.frac)! + Offset(0, -arc);
    }
    if ((seg.to - seg.from).abs() < 0.01) {
      return _pointAt(seg.from, boardW, benchTop);
    }
    // Square-by-square hop with weight: quick lift, crisp ease-out landing.
    final a = _pointAt(seg.from, boardW, benchTop);
    final b = _pointAt(seg.to, boardW, benchTop);
    final d = 1 - loc.frac;
    final e = 1 - d * d;
    final hop = sin(pi * loc.frac) * cell * 0.30;
    return Offset.lerp(a, b, e)! + Offset(0, -hop);
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ParchmentBackdrop(
      t: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _bannerRow(t),
                  _turnPlaque(t),
                  _PlayerStrip(
                    engine: _e,
                    theme: t,
                    tokenShape: widget.settings.tokenShape,
                    diceStyle: widget.settings.diceStyle,
                    onDiceTap: _onDiceTap,
                    paused: _paused,
                  ),
                  Expanded(child: _boardArea(t)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Text(
                      _hintText(),
                      style: Story.body(14, t: t, color: t.inkSoft),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              if (_paused && !_e.over)
                _PauseOverlay(
                  theme: t,
                  audio: widget.audio,
                  onResume: _togglePause,
                  onRestart: () {
                    setState(() {
                      _paused = false;
                      _overHandled = false;
                      _maxClimb = 0;
                      _maxSlide = 0;
                    });
                    _e.restart();
                  },
                  onQuit: () {
                    // Abandoned: no winner, no standings (RULES §10/§12 TC-12).
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerRow(StoryThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Row(
        children: [
          BrassRoundButton(
              icon: _paused ? Icons.play_arrow : Icons.pause,
              t: t,
              size: 40,
              onTap: _togglePause),
          Expanded(
            child: Column(
              children: [
                Text('Snakes & Ladders',
                    style: Story.titleSmall(22, t: t)),
                Text('Virtues Ascend • Vices Descend',
                    style: Story.caption(11, t: t)),
              ],
            ),
          ),
          BrassRoundButton(
              icon: Icons.settings,
              t: t,
              size: 40,
              onTap: () async {
                widget.audio.click();
                final wasPaused = _paused;
                if (!wasPaused) {
                  setState(() {
                    _paused = true;
                    _e.setPaused(true);
                  });
                }
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    audio: widget.audio,
                    settings: widget.settings,
                  ),
                ));
                widget.audio.configure(
                  musicOn: widget.settings.musicOn,
                  sfxOn: widget.settings.sfxOn,
                  volume: widget.settings.volume,
                );
                if (mounted && !wasPaused) {
                  setState(() {
                    _paused = false;
                    _e.setPaused(false);
                  });
                }
              }),
        ],
      ),
    );
  }

  Widget _turnPlaque(StoryThemeDef t) {
    final cur = _e.current;
    final pos = _e.pos[_e.turn];
    final need = 100 - pos;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: t.parchmentDeep.withValues(alpha: 0.65),
          border: Border.all(color: t.accent, width: 1.8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TokenPawn(
                  color: t.pawnColors[cur.colorIndex],
                  size: 20,
                  shape: widget.settings.tokenShape,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _e.over
                        ? '${cur.name} wins!'
                        : '${cur.name}${cur.isBot ? ' (clockwork)' : ''}${pos > 0 && need <= 6 && !_e.over ? ' — needs $need' : ''}',
                    style: Story.titleSmall(16, t: t),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _e.banner,
              style: Story.body(13, t: t, color: t.inkSoft),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardArea(StoryThemeDef t) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final boardW = min(c.maxWidth - 20, c.maxHeight - 64);
        const benchH = 46.0;
        return Center(
          child: SizedBox(
            width: boardW,
            child: WoodPanel(
              t: t,
              padding: const EdgeInsets.all(8),
              radius: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: boardW - 16,
                    height: boardW - 16,
                    child: AnimatedBuilder(
                      animation: _travelCtrl,
                      builder: (_, _) => Stack(
                        children: [
                          _grid(boardW - 16, t),
                          CustomPaint(
                            size: Size(boardW - 16, boardW - 16),
                            painter: _LinksPainter(
                                boardW: boardW - 16, theme: t),
                          ),
                          ..._pawns(boardW - 16, 0, t),
                          _activeRing(boardW - 16, t),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: benchH,
                    child: _bench(boardW - 16, t),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _grid(double s, StoryThemeDef t) {
    final cell = s / 10;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
      itemCount: 100,
      itemBuilder: (_, idx) {
        final n = 100 - idx;
        final light = ((n - 1) ~/ 10 + (n - 1) % 10).isEven;
        Color bg = light ? t.parchment : t.parchmentDeep;
        if (SlEngine.snakes.containsKey(n)) {
          bg = Color.lerp(bg, t.snakeGreen, 0.16)!;
        } else if (SlEngine.ladders.containsKey(n)) {
          bg = Color.lerp(bg, t.goldLeaf, 0.22)!;
        }
        return Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
                color: t.ink.withValues(alpha: 0.18), width: 0.5),
          ),
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 2, top: 1),
          child: Text('$n',
              style: Story.numeral(cell * 0.26, t: t)),
        );
      },
    );
  }

  List<Widget> _pawns(double boardW, double benchTop, StoryThemeDef t) {
    final out = <Widget>[];
    final cell = boardW / 10;
    final travel = _e.travel;
    for (int i = 0; i < _e.n; i++) {
      final isTraveling = travel != null && travel.pi == i;
      final p = _e.pos[i];
      if (p <= 0 && !isTraveling) continue; // on the bench
      final Offset ctr;
      if (isTraveling) {
        ctr = _travelPoint(travel, _travelCtrl.value, boardW, benchTop);
        // Segment sounds: find which segment we're in.
        final loc = travel.locate(_travelCtrl.value);
        _segSound(travel.segs.indexOf(loc.seg), loc.seg);
      } else {
        ctr = cellCenter(p, boardW);
      }
      out.add(Positioned(
        left: ctr.dx - cell * 0.32 + (i % 2) * cell * 0.22,
        top: ctr.dy - cell * 0.42 + (i ~/ 2) * cell * 0.20,
        child: IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(boxShadow: [
              BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 5,
                  offset: Offset(0, 3)),
            ]),
            child: TokenPawn(
              color: t.pawnColors[_e.players[i].colorIndex],
              size: cell * 0.62,
              shape: widget.settings.tokenShape,
            ),
          ),
        ),
      ));
    }
    return out;
  }

  Widget _activeRing(double boardW, StoryThemeDef t) {
    final travel = _e.travel;
    if (_e.over || travel != null) return const SizedBox.shrink();
    final p = _e.pos[_e.turn];
    if (p <= 0) return const SizedBox.shrink();
    final cell = boardW / 10;
    final c = cellCenter(p, boardW);
    return Positioned(
      left: c.dx - cell * 0.44,
      top: c.dy - cell * 0.44,
      child: IgnorePointer(
        child: Container(
          width: cell * 0.88,
          height: cell * 0.88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.accent, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: t.accent.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: Offset.zero),
            ],
          ),
        ),
      ),
    );
  }

  /// Off-board pawns wait on the bench; the traveling pawn starts its entry
  /// hop from its own slot.
  Widget _bench(double boardW, StoryThemeDef t) {
    final travel = _e.travel;
    return Row(
      children: [
        for (int i = 0; i < _e.n; i++)
          Expanded(
            child: Center(
              child: Builder(builder: (_) {
                final onBoard = _e.pos[i] > 0;
                final isTraveling = travel != null && travel.pi == i;
                if (onBoard || isTraveling) {
                  return Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: t.accent.withValues(alpha: 0.5), width: 1.5),
                      color: t.ink.withValues(alpha: 0.08),
                    ),
                  );
                }
                return TokenPawn(
                  color: t.pawnColors[_e.players[i].colorIndex],
                  size: 22,
                  shape: widget.settings.tokenShape,
                );
              }),
            ),
          ),
      ],
    );
  }

  String _hintText() {
    if (_e.over) return '';
    if (_paused) return 'Paused — the pieces wait patiently.';
    switch (_e.phase) {
      case SlPhase.rollOff:
        return 'The roll-off decides who begins…';
      case SlPhase.rolling:
        return '${_e.current.name} is casting the die…';
      case SlPhase.awaitingRoll:
        return _e.current.isBot
            ? '${_e.current.name} contemplates the die…'
            : 'Your turn — tap your dice!';
      case SlPhase.animating:
        return '';
      case SlPhase.over:
        return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Player strip: EVERY side gets its own dice. The current player's dice
// activates and rolls with a real-time animation on THEIR card — human or
// bot. During the roll-off each contender's die shows their own roll.
// ---------------------------------------------------------------------------
class _PlayerStrip extends StatelessWidget {
  final SlEngine engine;
  final StoryThemeDef theme;
  final int tokenShape;
  final int diceStyle;
  final void Function(int pi) onDiceTap;
  final bool paused;

  const _PlayerStrip({
    required this.engine,
    required this.theme,
    required this.tokenShape,
    required this.diceStyle,
    required this.onDiceTap,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < engine.n; i++)
            Expanded(
              child: _PlayerCard(
                engine: engine,
                theme: theme,
                pi: i,
                tokenShape: tokenShape,
                diceStyle: diceStyle,
                onDiceTap: onDiceTap,
                paused: paused,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final SlEngine engine;
  final StoryThemeDef theme;
  final int pi;
  final int tokenShape;
  final int diceStyle;
  final void Function(int pi) onDiceTap;
  final bool paused;

  const _PlayerCard({
    required this.engine,
    required this.theme,
    required this.pi,
    required this.tokenShape,
    required this.diceStyle,
    required this.onDiceTap,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    final p = engine.players[pi];
    final isCurrent = engine.turn == pi && !engine.over;
    final rolling = engine.phase == SlPhase.rolling && engine.lastRollBy == pi;
    final canRoll = !paused &&
        engine.awaitingRoll &&
        engine.turn == pi &&
        !p.isBot;
    int shown;
    if (engine.phase == SlPhase.rollOff) {
      shown = engine.rollOffValues[pi] ?? 0;
    } else if (engine.lastRollBy == pi && engine.dice != 0) {
      shown = engine.dice;
    } else {
      shown = 0;
    }
    return GestureDetector(
      onTap: canRoll ? () => onDiceTap(pi) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isCurrent
              ? theme.parchmentDeep.withValues(alpha: 0.85)
              : theme.parchmentDeep.withValues(alpha: 0.35),
          border: Border.all(
            color: isCurrent ? theme.accentLight : theme.accent.withValues(alpha: 0.45),
            width: isCurrent ? 2.5 : 1.2,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                      color: theme.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: Offset.zero),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TokenPawn(
                    color: theme.pawnColors[p.colorIndex],
                    size: 18,
                    shape: tokenShape),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    p.name,
                    style: Story.body(12, t: theme, color: theme.ink),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            if (p.isBot)
              Text('⚙ clockwork',
                  style: Story.caption(10, t: theme)),
            const SizedBox(height: 4),
            rolling
                ? _RollingDice(size: 46, diceStyle: diceStyle)
                : StoryDie(value: shown, size: 46, style: diceStyle),
            const SizedBox(height: 2),
            Text(
              engine.pos[pi] > 0 ? 'sq ${engine.pos[pi]}' : 'off board',
              style: Story.caption(10, t: theme),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real-time rolling animation: faces flicker while the engine settles.
class _RollingDice extends StatefulWidget {
  final double size;
  final int diceStyle;
  const _RollingDice({required this.size, required this.diceStyle});

  @override
  State<_RollingDice> createState() => _RollingDiceState();
}

class _RollingDiceState extends State<_RollingDice> {
  final _rand = Random();
  int _face = 3;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (mounted) setState(() => _face = 1 + _rand.nextInt(6));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoryDie(value: _face, size: widget.size, style: widget.diceStyle);
  }
}

// ---------------------------------------------------------------------------
class _LinksPainter extends CustomPainter {
  final double boardW;
  final StoryThemeDef theme;
  _LinksPainter({required this.boardW, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in SlEngine.ladders.entries) {
      LadderPainter(
        from: _GameScreenState.cellCenter(e.key, boardW),
        to: _GameScreenState.cellCenter(e.value, boardW),
        scale: (boardW / 10) / 34,
        wood: theme.woodMid,
      ).paint(canvas, size);
    }
    for (final e in SlEngine.snakes.entries) {
      SnakePainter(
        from: _GameScreenState.cellCenter(e.key, boardW),
        to: _GameScreenState.cellCenter(e.value, boardW),
        scale: (boardW / 10) / 34,
        base: theme.snakeGreen,
        dark: theme.snakeGreen.withValues(alpha: 0.75),
      ).paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _LinksPainter old) =>
      old.boardW != boardW || old.theme != theme;
}

// ---------------------------------------------------------------------------
class _PauseOverlay extends StatelessWidget {
  final StoryThemeDef theme;
  final StoryAudio audio;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  const _PauseOverlay({
    required this.theme,
    required this.audio,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 44),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: theme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.accent, width: 2.5),
            boxShadow: Story.paperShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('A Pause in the Tale',
                  style: Story.titleSmall(24, t: theme)),
              const SizedBox(height: 4),
              Text('The pieces wait patiently.',
                  style: Story.caption(13, t: theme)),
              const SizedBox(height: 18),
              WoodButton(
                  label: 'Resume', t: theme, fontSize: 18, onTap: () {
                audio.click();
                onResume();
              }),
              const SizedBox(height: 12),
              WoodButton(
                  label: 'Restart Tale', t: theme, fontSize: 18, onTap: () {
                audio.click();
                onRestart();
              }),
              const SizedBox(height: 12),
              WoodButton(
                  label: 'Quit to Menu', t: theme, fontSize: 18, onTap: () {
                audio.click();
                onQuit();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _WinnerDialog extends StatelessWidget {
  final SlEngine engine;
  final StoryThemeDef theme;
  final StoryAudio audio;
  final StorySettings settings;
  final bool humanWon;
  const _WinnerDialog({
    required this.engine,
    required this.theme,
    required this.audio,
    required this.settings,
    required this.humanWon,
  });

  @override
  Widget build(BuildContext context) {
    final order = engine.standings(engine.winner!);
    const medals = ['👑', '🥈', '🥉', '4th'];
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: theme.parchment,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.accent, width: 3),
          boxShadow: Story.paperShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(humanWon ? 'Victory!' : 'The clockwork wins!',
                style: Story.title(30, t: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              '${engine.players[engine.winner!].name} reaches square 100 first!',
              style: Story.body(15, t: theme, color: theme.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            for (int r = 0; r < order.length; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(medals[r],
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center),
                    ),
                    TokenPawn(
                      color: theme.pawnColors[
                          engine.players[order[r]].colorIndex],
                      size: 24,
                      shape: settings.tokenShape,
                      crowned: r == 0,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(engine.players[order[r]].name,
                          style: Story.body(15, t: theme)),
                    ),
                    Text('sq ${engine.pos[order[r]]}',
                        style: Story.caption(13, t: theme)),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            WoodButton(
                label: 'Play Again', t: theme, fontSize: 19, onTap: () {
              audio.gameStart();
              Navigator.of(context).pop(true);
            }),
            const SizedBox(height: 12),
            WoodButton(
                label: 'Main Menu', t: theme, fontSize: 19, onTap: () {
              audio.click();
              Navigator.of(context).pop(false);
            }),
          ],
        ),
      ),
    );
  }
}

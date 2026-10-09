import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'audio.dart';
import 'engine.dart';
import 'settings.dart';
import 'settings_screen.dart';
import 'snakes_theme.dart';
import 'winner_screen.dart';

/// How many humans sit at the table (1..playerCount); the rest are clockwork.
class GameConfig {
  final int playerCount;
  final int humans;
  const GameConfig({required this.playerCount, required this.humans});
}

/// Center of square n (1..100) in a size×size board, boustrophedon layout.
Offset cellCenter(int n, double size) {
  final cell = size / 10;
  final r0 = (n - 1) ~/ 10; // 0 = bottom row
  final pr = (n - 1) % 10;
  final col = r0.isEven ? pr : 9 - pr;
  final row = 9 - r0;
  return Offset((col + 0.5) * cell, (row + 0.5) * cell);
}

/// Point along a serpent's S-curve (mirrors SnakePainter's sway).
Offset snakePathPoint(Offset from, Offset to, double t) {
  final dir = to - from;
  final len = dir.distance;
  if (len < 1) return from;
  final n = dir / len;
  final normal = Offset(-n.dy, n.dx);
  final edge = (t == 0 || t == 1) ? 0.15 : 1.0;
  final sway = sin(t * pi * 3) * len * 0.09 * edge;
  return from + dir * t + normal * sway;
}

class SnakesGameScreen extends StatefulWidget {
  final GameConfig config;
  const SnakesGameScreen({super.key, required this.config});

  @override
  State<SnakesGameScreen> createState() => _SnakesGameScreenState();
}

class _SnakesGameScreenState extends State<SnakesGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final SlEngine _engine;
  late final List<int> _displayPos; // animated mirror of _engine.pos
  final _rand = Random();

  int _dice = 0;
  bool _rolling = false;
  bool _busy = false; // token animating
  bool _won = false;
  bool _paused = false;
  bool _inRollOff = true;
  String _banner = 'The parlour gathers…';
  String _status = '';
  Timer? _diceTimer;
  Timer? _botTimer;

  // pawn travel animation (hops, climbs, slides)
  late final AnimationController _travelCtrl;
  int _animPlayer = -1;
  Offset _animFrom = Offset.zero;
  Offset _animTo = Offset.zero;
  bool _animSnake = false;
  double _boardSize = 300;

  int _maxClimb = 0;
  int _maxSlide = 0;

  bool get _canRoll =>
      !_inRollOff && !_busy && !_rolling && !_won && !_paused && !_engine.current.isBot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cfg = widget.config;
    final players = [
      for (int i = 0; i < cfg.playerCount; i++)
        SlPlayer(name: StTheme.pawnNames[i], colorIndex: i, isBot: i >= cfg.humans),
    ];
    _engine = SlEngine(players: players);
    _displayPos = List.filled(cfg.playerCount, 0);
    _travelCtrl = AnimationController(vsync: this);
    SlAudio.instance.playMusic('audio/music_game.wav');
    SlAudio.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runRollOff());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _diceTimer?.cancel();
    _botTimer?.cancel();
    _travelCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SlAudio.instance.stopMusic();
      if (!_won && !_inRollOff && mounted) _openPause(auto: true);
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && !_won) {
        SlAudio.instance.playMusic(_won ? 'audio/music_menu.wav' : 'audio/music_game.wav');
      }
    }
  }

  // ---------------- roll-off ----------------

  Future<void> _runRollOff() async {
    final rounds = <({List<int> rolls, List<int> contenders})>[];
    _engine.rollOff(_rand, onRound: (rolls, contenders) {
      rounds.add((rolls: rolls, contenders: contenders));
    });
    for (final round in rounds) {
      for (int k = 0; k < round.contenders.length; k++) {
        if (!mounted) return;
        final pi = round.contenders[k];
        setState(() {
          _dice = round.rolls[k];
          _banner = '${_engine.players[pi].name} rolls… $_dice';
        });
        SlAudio.instance.dice();
        await Future.delayed(const Duration(milliseconds: 750));
      }
      if (!mounted) return;
      if (round.contenders.length > 1) {
        final names = [for (final pi in round.contenders) _engine.players[pi].name].join(' and ');
        setState(() => _banner = 'A tie! $names roll again…');
        await Future.delayed(const Duration(milliseconds: 900));
      }
    }
    if (!mounted) return;
    setState(() {
      _inRollOff = false;
      _dice = 0;
      _banner = '${_engine.current.name} begins the ascent!';
      _updateStatus();
    });
    await Future.delayed(const Duration(milliseconds: 800));
    _maybeBot();
  }

  void _updateStatus() {
    final cur = _engine.current;
    final need = 100 - _engine.pos[_engine.turn];
    _status = 'Round ${_engine.round} • ${cur.name}${need <= 6 && _engine.pos[_engine.turn] > 0 ? ' — needs $need' : ''}';
  }

  // ---------------- turns ----------------

  void _maybeBot() {
    if (_won || _paused || _inRollOff || !_engine.current.isBot || _busy || _rolling) return;
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _won || _paused || _busy || _rolling || !_engine.current.isBot) return;
      _roll();
    });
  }

  void _roll() {
    if (_won || _rolling || _busy || _paused || _inRollOff) return;
    setState(() {
      _rolling = true;
      _banner = '${_engine.current.name} casts the die…';
    });
    SlAudio.instance.dice();
    int ticks = 0;
    _diceTimer?.cancel();
    _diceTimer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      ticks++;
      setState(() => _dice = _rand.nextInt(6) + 1);
      if (ticks >= 9) {
        t.cancel();
        if (!mounted) return;
        setState(() => _rolling = false);
        _animateMove();
      }
    });
  }

  Future<void> _travel(int player, Offset from, Offset to,
      {required bool snake, required Duration duration}) async {
    _animPlayer = player;
    _animFrom = from;
    _animTo = to;
    _animSnake = snake;
    _travelCtrl.duration = duration;
    await _travelCtrl.forward(from: 0);
    if (!mounted) return;
    _animPlayer = -1;
  }

  /// Where a pawn waits before entering the board (below the board, by the tray).
  Offset get _benchPoint => Offset(_boardSize * 0.5, _boardSize + 26);

  Future<void> _animateMove() async {
    if (_won || !mounted) return;
    final pi = _engine.turn;
    final roll = _dice;
    final move = _engine.applyRoll(roll);
    setState(() {
      _dice = 0;
      _busy = true;
      _banner = '${_engine.current.name} rolls a $roll…';
    });

    if (move.overshoot) {
      final need = 100 - move.startPos;
      setState(() => _banner = 'Too far! ${_engine.players[pi].name} needs exactly $need.');
      SlAudio.instance.invalid();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted || _won) return;
      _endTurn(extra: false);
      return;
    }

    // hop forward square by square
    int cur = move.startPos;
    for (final s in move.steps) {
      final from = cur == 0 ? _benchPoint : cellCenter(cur, _boardSize);
      await _travel(pi, from, cellCenter(s, _boardSize),
          snake: false, duration: const Duration(milliseconds: 150));
      if (!mounted || _won) return;
      cur = s;
      setState(() => _displayPos[pi] = s);
      SlAudio.instance.hop();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _won) return;

    // ladders then snakes (chained, in engine order)
    for (final hop in move.climbs) {
      setState(() => _banner = 'A ladder! ${_engine.players[pi].name} climbs to ${hop.to}!');
      SlAudio.instance.ladder();
      _maxClimb = max(_maxClimb, hop.delta);
      await _travel(pi, cellCenter(hop.from, _boardSize), cellCenter(hop.to, _boardSize),
          snake: false, duration: const Duration(milliseconds: 750));
      if (!mounted || _won) return;
      setState(() => _displayPos[pi] = hop.to);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    for (final hop in move.slides) {
      setState(() => _banner = 'A serpent! ${_engine.players[pi].name} slides to ${hop.to}…');
      SlAudio.instance.snake();
      _maxSlide = max(_maxSlide, hop.delta);
      await _travel(pi, cellCenter(hop.from, _boardSize), cellCenter(hop.to, _boardSize),
          snake: true, duration: const Duration(milliseconds: 950));
      if (!mounted || _won) return;
      setState(() => _displayPos[pi] = hop.to);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (move.won) {
      _finish(pi);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted || _won) return;
    if (move.extraRoll) {
      setState(() => _banner = 'A six! ${_engine.players[pi].name} rolls again!');
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted || _won) return;
      setState(() => _busy = false);
      _maybeBot();
    } else {
      _endTurn(extra: false);
    }
  }

  void _endTurn({required bool extra}) {
    if (_won) return;
    _engine.endTurn(keepTurn: extra);
    setState(() {
      _busy = false;
      _updateStatus();
      _banner = '${_engine.current.name}\u2019s turn — cast the die!';
    });
    _maybeBot();
  }

  void _finish(int pi) {
    if (_won) return;
    _won = true;
    _diceTimer?.cancel();
    _botTimer?.cancel();
    final winner = _engine.players[pi];
    SlAudio.instance.win();
    if (winner.isBot) {
      Future.delayed(const Duration(milliseconds: 1400), () => SlAudio.instance.lose());
    }
    unawaited(SlSettings.instance.recordWin(winner.colorIndex));
    unawaited(SlSettings.instance.recordClimb(_maxClimb));
    unawaited(SlSettings.instance.recordSlide(_maxSlide));
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WinnerScreen(
            engine: _engine,
            winner: pi,
            config: widget.config,
          ),
        ),
      );
    });
  }

  // ---------------- pause ----------------

  Future<void> _openPause({bool auto = false}) async {
    if (_paused || _won) return;
    setState(() => _paused = true);
    SlAudio.instance.click();
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: !auto,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: StTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StTheme.brass, width: 2.5),
            boxShadow: StTheme.paperShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('A Pause in the Tale', style: StTheme.titleSmall),
              const SizedBox(height: 4),
              Text('The pieces wait patiently.', style: StTheme.caption),
              const SizedBox(height: 18),
              WoodButton(
                label: 'Resume',
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                onTap: () => Navigator.of(ctx).pop('resume'),
              ),
              const SizedBox(height: 12),
              WoodButton(
                label: 'Restart Tale',
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                onTap: () => Navigator.of(ctx).pop('restart'),
              ),
              const SizedBox(height: 12),
              WoodButton(
                label: 'Quit to Menu',
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                onTap: () => Navigator.of(ctx).pop('quit'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _paused = false);
    if (choice == 'restart') {
      _diceTimer?.cancel();
      _botTimer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SnakesGameScreen(config: widget.config)),
      );
    } else if (choice == 'quit') {
      // Abandoned: no winner, no standings (RULES §10/§12 TC-12).
      Navigator.of(context).pop();
    } else {
      _maybeBot();
    }
  }

  void _openSettings() {
    SlAudio.instance.click();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
        .then((_) {
      if (mounted && !_won) SlAudio.instance.playMusic('audio/music_game.wav');
    });
  }

  // ---------------- rendering ----------------

  Offset _pawnOffset(int i) {
    if (i == _animPlayer) {
      final t = Curves.easeInOut.transform(_travelCtrl.value.clamp(0.0, 1.0));
      if (_animSnake) return snakePathPoint(_animFrom, _animTo, t);
      return Offset.lerp(_animFrom, _animTo, t)!;
    }
    final p = _displayPos[i];
    if (p <= 0) return Offset.zero; // bench row handles these
    return cellCenter(p, _boardSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParchmentBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _buildBanner(),
              Expanded(child: _buildBoard()),
              _buildTray(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              BrassRoundButton(icon: Icons.pause, size: 40, onTap: () => _openPause()),
              Expanded(
                child: Column(
                  children: [
                    Text('Snakes & Ladders',
                        style: StTheme.titleSmall.copyWith(fontSize: 24)),
                    Text('Virtues Ascend • Vices Descend',
                        style: StTheme.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              BrassRoundButton(icon: Icons.settings, size: 40, onTap: _openSettings),
            ],
          ),
          const SizedBox(height: 4),
          Text(_status, style: StTheme.caption.copyWith(fontSize: 12.5, fontStyle: FontStyle.normal, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(_banner,
              style: StTheme.body.copyWith(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final s = min(c.maxWidth, c.maxHeight);
          _boardSize = s;
          final cell = s / 10;
          return Center(
            child: SizedBox(
              width: s,
              height: s,
              child: WoodPanel(
                padding: EdgeInsets.zero,
                radius: 10,
                child: AnimatedBuilder(
                  animation: _travelCtrl,
                  builder: (_, _) => Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                        itemCount: 100,
                        itemBuilder: (_, idx) {
                          final n = 100 - idx;
                          final light = ((n - 1) ~/ 10 + (n - 1) % 10).isEven;
                          Color bg = light ? const Color(0xFFFDF6E4) : StTheme.parchmentDeep;
                          if (SlEngine.snakes.containsKey(n)) {
                            bg = Color.lerp(bg, StTheme.snakeGreen, 0.16)!;
                          } else if (SlEngine.ladders.containsKey(n)) {
                            bg = Color.lerp(bg, StTheme.goldLeaf, 0.20)!;
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: bg,
                              border: Border.all(color: StTheme.inkBrown.withValues(alpha: 0.18), width: 0.5),
                            ),
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.only(left: 2, top: 1),
                            child: Text('$n', style: StTheme.numeral.copyWith(fontSize: cell * 0.26)),
                          );
                        },
                      ),
                      // ladders under snakes under pawns
                      CustomPaint(
                        size: Size(s, s),
                        painter: _BoardLinksPainter(cellSize: cell, boardSize: s),
                      ),
                      for (int i = 0; i < _engine.n; i++)
                        if (_displayPos[i] > 0 || i == _animPlayer)
                          Positioned(
                            left: _pawnOffset(i).dx - cell * 0.32 + (i % 2) * cell * 0.22,
                            top: _pawnOffset(i).dy - cell * 0.42 + (i ~/ 2) * cell * 0.20,
                            child: IgnorePointer(
                              child: Container(
                                decoration: const BoxDecoration(boxShadow: [
                                  BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3)),
                                ]),
                                child: WoodenPawn(
                                  color: StTheme.pawnColors[_engine.players[i].colorIndex],
                                  size: cell * 0.62,
                                ),
                              ),
                            ),
                          ),
                      // active-player brass ring
                      if (!_won && _displayPos[_engine.turn] > 0 && _animPlayer != _engine.turn)
                        Positioned(
                          left: cellCenter(_displayPos[_engine.turn], s).dx - cell * 0.44,
                          top: cellCenter(_displayPos[_engine.turn], s).dy - cell * 0.44,
                          child: IgnorePointer(
                            child: Container(
                              width: cell * 0.88,
                              height: cell * 0.88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: StTheme.brass, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x66B08D3E), blurRadius: 6, offset: Offset.zero),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTray() {
    final bench = [for (int i = 0; i < _engine.n; i++) if (_displayPos[i] == 0) i];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: WoodPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        radius: 14,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bench.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Awaiting entry: ', style: StTheme.caption),
                    for (final i in bench)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Opacity(
                          opacity: 0.85,
                          child: WoodenPawn(
                            color: StTheme.pawnColors[_engine.players[i].colorIndex],
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                // turn badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: StTheme.parchment,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: StTheme.brass, width: 1.8),
                    boxShadow: StTheme.brassShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WoodenPawn(
                        color: StTheme.pawnColors[_engine.current.colorIndex],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _engine.current.name.split(' ').last,
                        style: StTheme.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // dice tray
                Expanded(
                  child: GestureDetector(
                    onTap: _canRoll ? _roll : null,
                    child: Container(
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF4E331F),
                        border: Border.all(color: StTheme.brass, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
                          BoxShadow(color: Color(0x22000000), blurRadius: 2, offset: Offset(0, -2)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedRotation(
                            turns: _rolling ? _dice / 6 : 0,
                            duration: const Duration(milliseconds: 120),
                            child: IvoryDie(value: _dice, size: 56),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _canRoll ? _roll : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: _canRoll
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFD9B45C), StTheme.brass, Color(0xFF8A6B2A)],
                                      )
                                    : null,
                                color: _canRoll ? null : const Color(0xFF8A7A64),
                                border: Border.all(color: const Color(0xFF6E5220), width: 1.5),
                                boxShadow: StTheme.brassShadow,
                              ),
                              child: Text(
                                _rolling ? '…' : 'ROLL',
                                style: StTheme.buttonLabel.copyWith(
                                  fontSize: 19,
                                  color: _canRoll ? StTheme.inkBrown : StTheme.parchmentDeep,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _canRoll
                  ? 'Tap the die to cast it'
                  : _engine.current.isBot
                      ? '${_engine.current.name} contemplates the die…'
                      : _inRollOff
                          ? 'The roll-off decides who begins'
                          : 'The pieces are moving…',
              style: StTheme.caption.copyWith(color: StTheme.parchmentDeep),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardLinksPainter extends CustomPainter {
  final double cellSize;
  final double boardSize;
  _BoardLinksPainter({required this.cellSize, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in SlEngine.ladders.entries) {
      LadderPainter(
        from: cellCenter(e.key, boardSize),
        to: cellCenter(e.value, boardSize),
        scale: cellSize / 34,
      ).paint(canvas, size);
    }
    for (final e in SlEngine.snakes.entries) {
      SnakePainter(
        from: cellCenter(e.key, boardSize),
        to: cellCenter(e.value, boardSize),
        scale: cellSize / 34,
      ).paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardLinksPainter old) => false;
}

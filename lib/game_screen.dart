import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Snakes and Ladders — the family classic. Tap the dice, ride your luck:
/// ladders zoom you up, snakes send you sliding down. Exact 100 wins.
class SnakesLaddersScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const SnakesLaddersScreen({super.key, required this.players, required this.callbacks});

  @override
  State<SnakesLaddersScreen> createState() => _SnakesLaddersScreenState();
}

const _snakes = <int, int>{
  16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78,
};
const _ladders = <int, int>{
  1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100,
};
const _diceFaces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

/// Center of square n (1..100) in a size×size board, boustrophedon layout.
Offset _cellCenter(int n, double size) {
  final cell = size / 10;
  final r0 = (n - 1) ~/ 10; // 0 = bottom row
  final pr = (n - 1) % 10;
  final col = r0.isEven ? pr : 9 - pr;
  final row = 9 - r0;
  return Offset((col + 0.5) * cell, (row + 0.5) * cell);
}

/// WORKAROUND (core bug): shell solo setup yields a single bot seat instead of
/// human+bot. Synthesize the missing bot locally so solo mode stays playable.
List<Player> _effectivePlayers(List<Player> src) {
  if (src.length > 1) return src;
  final h = src.first;
  return [
    Player(name: h.name, color: h.color, emoji: h.emoji, isBot: false),
    PlayerPresets.make(1, isBot: true),
  ];
}

class _SnakesLaddersScreenState extends State<SnakesLaddersScreen> {
  late final List<Player> _ps;
  late List<int> _pos; // 0 = waiting to start
  int _turn = 0;
  int _dice = 0;
  bool _rolling = false;
  bool _busy = false; // token animating
  bool _over = false;
  String _banner = ' • tap the dice to roll! 🎲';
  Timer? _diceTimer;
  final _rand = Random();

  int get _n => _ps.length;
  Player get _me => _ps[_turn];
  bool get _solo => _ps.length != widget.players.length;

  @override
  void initState() {
    super.initState();
    _ps = _effectivePlayers(widget.players);
    _pos = List.filled(_n, 0);
    widget.callbacks.setActivePlayer(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  @override
  void dispose() {
    _diceTimer?.cancel();
    super.dispose();
  }

  void _maybeBot() {
    if (_over || !_me.isBot || _busy) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _over || _busy || _rolling || !_me.isBot) return;
      _roll();
    });
  }

  void _roll() {
    if (_over || _rolling || _busy || _dice != 0) return;
    setState(() => _rolling = true);
    Sfx.click();
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
        setState(() => _rolling = false);
        _hop();
      }
    });
  }

  Future<void> _hop() async {
    if (_over) return;
    final roll = _dice;
    setState(() {
      _dice = 0;
      _busy = true;
      _banner = ' • ${_me.name} rolled $roll!';
    });
    final target = _pos[_turn] + roll;
    if (target > 100) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _over) return;
      setState(() => _banner = ' • too high! Need exactly ${100 - _pos[_turn]} 😬');
      Sfx.tap();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || _over) return;
      _endTurn();
      return;
    }
    // hop forward step by step — juicy!
    for (int s = _pos[_turn] + 1; s <= target; s++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted || _over) return;
      setState(() => _pos[_turn] = s);
      Sfx.move();
    }
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _over) return;
    if (_snakes.containsKey(target)) {
      setState(() => _banner = ' • 🐍 SNAKE! ${_me.name} slides down!');
      Sfx.lose();
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted || _over) return;
      setState(() => _pos[_turn] = _snakes[target]!);
    } else if (_ladders.containsKey(target)) {
      setState(() => _banner = ' • 🪜 LADDER! ${_me.name} zooms up! Wheee!');
      Sfx.click();
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted || _over) return;
      setState(() => _pos[_turn] = _ladders[target]!);
    }
    _syncScores();
    if (_pos[_turn] == 100) {
      _finish(_turn);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _over) return;
    _endTurn();
  }

  void _endTurn() {
    if (_over) return;
    setState(() {
      _busy = false;
      _turn = (_turn + 1) % _n;
      _banner = ' • ${_ps[_turn].name}\'s turn — tap the dice! 🎲';
    });
    widget.callbacks.setActivePlayer(min(_turn, widget.players.length - 1));
    _maybeBot();
  }

  void _syncScores() {
    for (int i = 0; i < _n; i++) {
      _ps[i].score = _pos[i];
      if (i < widget.players.length) widget.players[i].score = _pos[i];
    }
    widget.callbacks.refreshHud();
  }

  void _finish(int pi) {
    if (_over) return;
    _over = true;
    _diceTimer?.cancel();
    final w = _ps[pi];
    widget.callbacks.finish(
      winner: w,
      headline: '🏆 ${w.name} hits 100!',
      subline: 'Climbed every ladder, dodged every snake. Absolute legend! 🐍✨',
    );
  }

  String get _diceHint {
    if (_over) return '';
    if (_busy) return 'On the move…';
    if (_me.isBot) return '${_me.name} is rolling…';
    if (_rolling) return 'Rolling… 🌀';
    return 'Tap the dice! 🎲';
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final canRoll = !_busy && !_rolling && !_over && !_me.isBot;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            const SizedBox(height: 4),
            TurnBanner(player: _me, action: _banner),
            if (_solo) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _n; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${_ps[i].emoji} ${_pos[i]}',
                        style: TextStyle(
                            color: t.text, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final s = c.maxWidth;
                  final cell = s / 10;
                  return Container(
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10),
                          itemCount: 100,
                          itemBuilder: (_, idx) {
                            final n = 100 - idx;
                            final isSnakeHead = _snakes.containsKey(n);
                            final isSnakeTail = _snakes.containsValue(n);
                            final isLadderFoot = _ladders.containsKey(n);
                            final isLadderTop = _ladders.containsValue(n);
                            Color bg = Colors.transparent;
                            String mark = '';
                            if (isSnakeHead) {
                              bg = Colors.red.withValues(alpha: 0.22);
                              mark = '🐍';
                            } else if (isLadderFoot) {
                              bg = Colors.green.withValues(alpha: 0.22);
                              mark = '🪜';
                            } else if (isSnakeTail || isLadderTop) {
                              bg = t.primary.withValues(alpha: 0.08);
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: bg,
                                border: Border.all(
                                    color: t.muted.withValues(alpha: 0.12), width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: mark.isEmpty
                                  ? Text('$n',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: t.muted.withValues(alpha: 0.75),
                                          fontWeight: FontWeight.w700))
                                  : Text(mark, style: const TextStyle(fontSize: 15)),
                            );
                          },
                        ),
                        CustomPaint(
                          size: Size(s, s),
                          painter: _LinksPainter(snakes: _snakes, ladders: _ladders),
                        ),
                        // tokens
                        for (int i = 0; i < _n; i++)
                          if (_pos[i] > 0)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 140),
                              left: _cellCenter(_pos[i], s).dx -
                                  cell * 0.3 +
                                  (i % 2) * cell * 0.28,
                              top: _cellCenter(_pos[i], s).dy -
                                  cell * 0.3 +
                                  (i ~/ 2) * cell * 0.28,
                              child: Container(
                                width: cell * 0.6,
                                height: cell * 0.6,
                                decoration: BoxDecoration(
                                  color: _ps[i].color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // waiting-to-start tokens
            if (_pos.any((p) => p == 0))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _n; i++)
                      if (_pos[i] == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _ps[i].color.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(color: _ps[i].color, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(_ps[i].emoji,
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: canRoll ? _roll : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: t.radius,
                      border: Border.all(
                        color: canRoll ? t.primary : t.muted.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: canRoll ? 0.35 : 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dice == 0 ? '🎲' : _diceFaces[_dice - 1],
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _diceHint,
                    style: TextStyle(
                        color: t.muted, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

/// Draws the snaky curves and ladder rails over the board.
class _LinksPainter extends CustomPainter {
  final Map<int, int> snakes;
  final Map<int, int> ladders;

  _LinksPainter({required this.snakes, required this.ladders});

  @override
  void paint(Canvas canvas, Size size) {
    // snakes: wiggly red curves from head to tail
    for (final e in snakes.entries) {
      final a = _cellCenter(e.key, size.width);
      final b = _cellCenter(e.value, size.width);
      final mid = (a + b) / 2;
      final dir = Offset(-(b.dy - a.dy), b.dx - a.dx);
      final len = dir.distance == 0 ? 1.0 : dir.distance;
      final ctrl = mid + (dir / len) * size.width * 0.06;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    // ladders: green rails with rungs
    for (final e in ladders.entries) {
      final a = _cellCenter(e.key, size.width);
      final b = _cellCenter(e.value, size.width);
      final rail = Paint()
        ..color = const Color(0xFF51CF66).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      final delta = b - a;
      final len = delta.distance == 0 ? 1.0 : delta.distance;
      final normal = Offset(-delta.dy / len, delta.dx / len) * size.width * 0.012;
      canvas.drawLine(a + normal, b + normal, rail);
      canvas.drawLine(a - normal, b - normal, rail);
      final rungs = (len / (size.width * 0.035)).floor().clamp(2, 8);
      for (int i = 1; i < rungs; i++) {
        final p = a + delta * (i / rungs);
        canvas.drawLine(p + normal, p - normal,
            rail..strokeWidth = 3);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinksPainter old) => false;
}

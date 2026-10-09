import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Snakes & Ladders engine — deterministic rules core with an engine-owned
/// turn state machine. Authoritative source: RULES.md.
///
/// Exemplar pattern (from Ludo): the engine (not UI timers) owns turn phases
/// and settles rolls/travel on its own timers; a watchdog recovers any phase
/// found without a live timer. Stuck states are impossible by construction.
///
/// Phases: rollOff -> awaitingRoll -> rolling -> animating -> (extra roll?)
/// awaitingRoll | (next turn) awaitingRoll ... -> over.
class SlPlayer {
  String name; // renameable
  final int colorIndex; // 0=Red, 1=Blue, 2=Green, 3=Yellow
  final bool isBot;
  SlPlayer({required this.name, required this.colorIndex, this.isBot = false});
}

/// 0 = easy, 1 = medium, 2 = hard. Per RULES.md §11 the game is pure chance,
/// so every difficulty plays identically; difficulty only changes the bot's
/// turn pacing (thinking delay), never the rules.
enum BotDifficulty { easy, medium, hard }

/// Turn phases owned entirely by the engine. The UI only renders.
enum SlPhase { rollOff, awaitingRoll, rolling, animating, over }

/// A ladder climb or snake slide event: from -> to.
class SlHop {
  final int from;
  final int to;
  final bool isLadder;
  const SlHop({required this.from, required this.to, required this.isLadder});
  int get delta => (to - from).abs();
}

/// Outcome of applying one die roll for the current player (RULES §4).
class SlMove {
  final int roll;
  final int startPos;
  final List<int> steps; // square after each forward hop (for animation)
  final bool overshoot;
  final List<SlHop> climbs; // ladder climbs in order
  final List<SlHop> slides; // snake slides in order
  final int finalPos;
  final bool won;
  final bool extraRoll;

  const SlMove({
    required this.roll,
    required this.startPos,
    required this.steps,
    required this.overshoot,
    required this.climbs,
    required this.slides,
    required this.finalPos,
    required this.won,
    required this.extraRoll,
  });
}

/// One segment of the visible travel timeline (square-by-square walk,
/// ladder climb, snake slide, or a dramatic pause).
class SlSeg {
  final double from; // fractional square (0 = off board)
  final double to;
  final bool isSnake;
  final bool isClimb;
  final int ms;
  const SlSeg({
    required this.from,
    required this.to,
    this.isSnake = false,
    this.isClimb = false,
    required this.ms,
  });
}

/// The full visible travel for one turn. The logical move is applied at once
/// (engine.pos is final); the UI interpolates the pawn along [segs] so every
/// square, climb and slide is SEEN — never silently auto-played.
class SlTravel {
  final int pi;
  final SlMove move;
  final List<SlSeg> segs;
  final int totalMs;
  final DateTime startedAt = DateTime.now();

  SlTravel({required this.pi, required this.move})
      : segs = _build(move),
        totalMs = _build(move).fold(0, (a, s) => a + s.ms);

  static List<SlSeg> _build(SlMove m) {
    final out = <SlSeg>[];
    if (m.overshoot) {
      // Pawn stays put; linger so the "too far" banner is read.
      out.add(SlSeg(from: m.startPos.toDouble(), to: m.startPos.toDouble(), ms: 1100));
      return out;
    }
    // Square-by-square walk: ~175ms per square, each with its own hop.
    for (final s in m.steps) {
      out.add(SlSeg(from: (s - 1).toDouble(), to: s.toDouble(), ms: 175));
    }
    var needsPause = m.climbs.isNotEmpty || m.slides.isNotEmpty;
    if (needsPause) {
      out.add(SlSeg(from: m.steps.last.toDouble(), to: m.steps.last.toDouble(), ms: 240));
    }
    for (final h in m.climbs) {
      out.add(SlSeg(from: h.from.toDouble(), to: h.to.toDouble(), isClimb: true, ms: 780));
      out.add(SlSeg(from: h.to.toDouble(), to: h.to.toDouble(), ms: 240));
    }
    for (final h in m.slides) {
      out.add(SlSeg(from: h.from.toDouble(), to: h.to.toDouble(), isSnake: true, ms: 980));
      out.add(SlSeg(from: h.to.toDouble(), to: h.to.toDouble(), ms: 240));
    }
    return out;
  }

  /// Locate the (fractional square, segment, in-segment fraction) at overall
  /// progress [p] in 0..1.
  ({double square, SlSeg seg, double frac}) locate(double p) {
    final target = (p.clamp(0.0, 1.0) * totalMs).round();
    var acc = 0;
    for (final s in segs) {
      if (target <= acc + s.ms) {
        final f = s.ms == 0 ? 1.0 : ((target - acc) / s.ms).clamp(0.0, 1.0);
        return (square: s.from + (s.to - s.from) * f, seg: s, frac: f);
      }
      acc += s.ms;
    }
    final s = segs.last;
    return (square: s.to, seg: s, frac: 1.0);
  }
}

/// UI hook for sounds / narration. Set by the screen.
enum SlEvent {
  rollOffTick, // one contender's roll-off die revealed (see rollOffPi/rollOffVal)
  rollOffDone, // roll-off finished, first player chosen
  diceRolling, // a turn's die started rolling
  moveSettled, // roll applied; [travel] holds the visible timeline
  overshoot, // roll would pass 100: pawn stays
  invalid, // illegal tap
  extraRoll, // a 6 grants another roll
  humanWon,
  botWon,
}

class SlEngine extends ChangeNotifier {
  // Fixed ladder map (foot -> top). RULES §2.
  static const ladders = <int, int>{
    1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100,
  };
  // Fixed snake map (head -> tail). RULES §2.
  static const snakes = <int, int>{
    16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78,
  };

  /// Guard against infinite chained resolution (RULES §7).
  static const maxChain = 10;
  static const rollDurationMs = 1100;

  final List<SlPlayer> players;
  final BotDifficulty botDifficulty;
  final List<int> pos; // 0 = off board, waiting to enter
  final Random _rand;

  int turn = 0;
  int round = 1;
  int dice = 0; // 0 = not rolled / consumed
  SlPhase phase = SlPhase.rollOff;
  SlTravel? travel;
  SlMove? lastMove;
  bool over = false;
  int? winner;
  String banner = '';
  int lastRollBy = -1; // player index whose dice is showing the value

  // Roll-off display state (UI shows each contender's die on their own card).
  int rollOffPi = -1;
  int rollOffVal = 0;
  final Map<int, int> rollOffValues = {};

  /// Strict one-roll-per-turn enforcement: a roll is GRANTED when entering
  /// awaitingRoll and CONSUMED by _beginRoll. Extra taps while consumed (or
  /// while the turn is settling) are ignored — tap-to-reroll is impossible.
  bool _rollConsumed = true;

  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  /// Test hook: synchronous mode — timers queue up and run via [drainTest]
  /// iteratively, so a full bot-vs-bot game completes without real delays
  /// and without deep recursion.
  final bool testMode;
  final List<void Function()> _testQueue = [];

  /// Test hook: when set, the next roll settles to this value instead of a
  /// random one. Consumed after one use.
  @visibleForTesting
  int? forcedRoll;

  void Function(SlEvent event)? onEvent;

  SlEngine({
    required this.players,
    this.botDifficulty = BotDifficulty.medium,
    this.testMode = false,
    Random? rand,
  })  : pos = List.filled(players.length, 0),
        _rand = rand ?? Random() {
    assert(players.length >= 2 && players.length <= 4);
    if (!testMode) {
      _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    }
    _beginRollOff();
  }

  int get n => players.length;
  SlPlayer get current => players[turn];
  bool get rolling => phase == SlPhase.rolling;
  bool get awaitingRoll => phase == SlPhase.awaitingRoll && !over;

  /// Bot thinking delay by difficulty (RULES §11: pacing only, rules identical).
  int get _botThinkMs => switch (botDifficulty) {
        BotDifficulty.easy => 1150,
        BotDifficulty.medium => 800,
        BotDifficulty.hard => 550,
      };

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed) return;
    if (testMode) {
      _testQueue.add(fn);
      return;
    }
    if (paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Test driver: run all queued phase transitions iteratively until the
  /// queue empties (game over) or [limit] events pass. Throws if the limit
  /// is hit — that is the stuck-state proof failing loudly.
  @visibleForTesting
  void drainTest({int limit = 500000}) {
    var count = 0;
    while (_testQueue.isNotEmpty) {
      if (++count > limit) {
        throw StateError('SlEngine stuck: $limit queued events without finishing');
      }
      _testQueue.removeAt(0)();
    }
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase via the
  /// watchdog. Respects [paused].
  void setPaused(bool v) {
    if (paused == v || _disposed || testMode) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// Every phase has a legal forward action, so stuck states are impossible
  /// by construction. Respects [paused].
  void _recover() {
    if (_disposed || over || paused || testMode || _timer != null) return;
    if (phase == SlPhase.rolling) {
      _settleRoll(); // rolling with no timer: settle immediately
    } else if (phase == SlPhase.animating && travel != null) {
      // Resume the interrupted travel with its remaining time.
      final t = travel!;
      final elapsed = DateTime.now().difference(t.startedAt).inMilliseconds;
      final remain = (t.totalMs - elapsed).clamp(60, t.totalMs);
      _arm(Duration(milliseconds: remain), _afterTravel);
    } else if (phase == SlPhase.animating) {
      _afterTravel();
    } else if (phase == SlPhase.awaitingRoll && current.isBot) {
      _botRoll();
    } else if (phase == SlPhase.rollOff) {
      _arm(const Duration(milliseconds: 500), _rollOffTick);
    }
  }

  // ------------------------------------------------------------ roll-off
  // RULES §3: each contender rolls once per round, highest starts; ties
  // re-roll among tied players only. Rounds are precomputed, then revealed
  // one contender at a time on engine-owned timers so every side's own dice
  // UI shows their roll.
  final List<List<int>> _roContenders = [];
  final List<List<int>> _roRolls = [];
  int _roWinner = 0;
  int _roRound = 0;
  int _roTick = 0;

  void _beginRollOff() {
    phase = SlPhase.rollOff;
    banner = 'The roll-off decides who begins…';
    _roContenders.clear();
    _roRolls.clear();
    rollOffValues.clear();
    rollOffPi = -1;
    var contenders = List<int>.generate(n, (i) => i);
    while (true) {
      final rolls = [for (final _ in contenders) _rand.nextInt(6) + 1];
      _roContenders.add(List<int>.of(contenders));
      _roRolls.add(rolls);
      final best = rolls.reduce(max);
      final next = [
        for (int i = 0; i < contenders.length; i++)
          if (rolls[i] == best) contenders[i]
      ];
      if (next.length == 1) break;
      contenders = next;
    }
    final lastRolls = _roRolls.last;
    final lastCont = _roContenders.last;
    final best = lastRolls.reduce(max);
    _roWinner = lastCont[lastRolls.indexOf(best)];
    _roRound = 0;
    _roTick = 0;
    notifyListeners();
    _arm(const Duration(milliseconds: 700), _rollOffTick);
  }

  void _rollOffTick() {
    if (_disposed || over || phase != SlPhase.rollOff) return;
    final contenders = _roContenders[_roRound];
    if (_roTick < contenders.length) {
      final pi = contenders[_roTick];
      final val = _roRolls[_roRound][_roTick];
      rollOffPi = pi;
      rollOffVal = val;
      rollOffValues[pi] = val;
      banner = '${players[pi].name} rolls… $val';
      onEvent?.call(SlEvent.rollOffTick);
      notifyListeners();
      _roTick++;
      _arm(const Duration(milliseconds: 750), _rollOffTick);
      return;
    }
    // Round complete.
    if (_roRound >= _roContenders.length - 1) {
      turn = _roWinner;
      rollOffPi = -1;
      banner = '${players[turn].name} begins the ascent!';
      onEvent?.call(SlEvent.rollOffDone);
      notifyListeners();
      _grantRoll();
      return;
    }
    banner = 'A tie! The tied players roll again…';
    notifyListeners();
    _roRound++;
    _roTick = 0;
    _arm(const Duration(milliseconds: 950), _rollOffTick);
  }

  // ------------------------------------------------------------- turn flow
  /// Human taps their own dice. Strict: exactly one roll per grant, and only
  /// the current player may roll.
  void roll() {
    if (!awaitingRoll || current.isBot || _rollConsumed) {
      onEvent?.call(SlEvent.invalid);
      return;
    }
    _beginRoll();
  }

  void _botRoll() {
    if (!awaitingRoll || !current.isBot || over || _rollConsumed) return;
    _beginRoll();
  }

  void _beginRoll() {
    if (_rollConsumed || over) return; // belt-and-suspenders: never double-roll
    _rollConsumed = true;
    phase = SlPhase.rolling;
    dice = 0;
    travel = null;
    lastMove = null;
    lastRollBy = turn;
    banner = '${current.name} casts the die…';
    onEvent?.call(SlEvent.diceRolling);
    notifyListeners();
    _arm(const Duration(milliseconds: rollDurationMs), _settleRoll);
  }

  /// Grant the current player a fresh roll (turn start or earned extra roll).
  void _grantRoll() {
    _rollConsumed = false;
    phase = SlPhase.awaitingRoll;
    dice = 0;
    notifyListeners();
    _afterPhase();
  }

  /// Engine-owned settle — the UI never calls this. No desync possible.
  void _settleRoll() {
    if (over || phase != SlPhase.rolling) return;
    phase = SlPhase.animating;
    dice = forcedRoll ?? (1 + _rand.nextInt(6));
    forcedRoll = null;
    final move = applyRoll(dice);
    lastMove = move;
    travel = SlTravel(pi: turn, move: move);
    if (move.overshoot) {
      final need = 100 - move.startPos;
      banner = 'Too far! ${current.name} needs exactly $need.';
      onEvent?.call(SlEvent.overshoot);
    } else if (move.won) {
      banner = move.climbs.isNotEmpty
          ? 'A ladder to victory! ${current.name} reaches 100!'
          : '${current.name} reaches 100!';
    } else if (move.climbs.isNotEmpty || move.slides.isNotEmpty) {
      banner = '${current.name} rolled a $dice…';
    } else {
      banner = '${current.name} rolled a $dice.';
    }
    onEvent?.call(SlEvent.moveSettled);
    notifyListeners();
    _arm(Duration(milliseconds: travel!.totalMs), _afterTravel);
  }

  void _afterTravel() {
    if (over) return;
    final move = lastMove;
    final pi = turn;
    travel = null;
    if (move == null) {
      _nextTurn();
      return;
    }
    if (move.won) {
      _finish(pi);
      return;
    }
    if (move.extraRoll) {
      // Exactly ONE bonus roll is granted here — never more.
      banner = 'A six! ${players[turn].name} rolls again!';
      onEvent?.call(SlEvent.extraRoll);
      _grantRoll();
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    if (over) return;
    turn = (turn + 1) % n;
    if (turn == 0) round++;
    banner = current.isBot ? '${current.name} is up…' : '${current.name}, cast the die!';
    // Fresh turn = fresh single roll grant.
    _grantRoll();
  }

  /// Called whenever we enter awaitingRoll: bots roll themselves.
  void _afterPhase() {
    if (over || phase != SlPhase.awaitingRoll) return;
    if (current.isBot) {
      _arm(Duration(milliseconds: _botThinkMs), _botRoll);
    }
  }

  void _finish(int pi) {
    over = true;
    phase = SlPhase.over;
    winner = pi;
    travel = null;
    banner = '${players[pi].name} wins the race!';
    notifyListeners();
    onEvent?.call(players[pi].isBot ? SlEvent.botWon : SlEvent.humanWon);
  }

  void restart() {
    _timer?.cancel();
    _testQueue.clear();
    paused = false;
    for (int i = 0; i < n; i++) {
      pos[i] = 0;
    }
    turn = 0;
    round = 1;
    dice = 0;
    travel = null;
    lastMove = null;
    over = false;
    winner = null;
    lastRollBy = -1;
    _rollConsumed = true;
    notifyListeners();
    _beginRollOff();
  }

  // ----------------------------------------------------------------- rules
  /// Applies [roll] for the current player. RULES §4:
  /// - pawn at 0 enters on the square equal to the roll (ladder feet apply);
  /// - overshoot (>100) -> pawn stays, turn passes (extraRoll: false);
  /// - ladder feet / snake heads resolve immediately (chained, max 10);
  /// - rolling 6 grants one extra roll (not after a win).
  SlMove applyRoll(int roll) {
    final start = pos[turn];
    final target = start + roll;
    if (target > 100) {
      return SlMove(
        roll: roll,
        startPos: start,
        steps: const [],
        overshoot: true,
        climbs: const [],
        slides: const [],
        finalPos: start,
        won: false,
        extraRoll: false,
      );
    }
    final steps = [for (int s = start + 1; s <= target; s++) s];
    int cur = target;
    final climbs = <SlHop>[];
    final slides = <SlHop>[];
    int guard = 0;
    while (guard++ < maxChain) {
      final lad = ladders[cur];
      final snk = snakes[cur];
      if (lad != null) {
        climbs.add(SlHop(from: cur, to: lad, isLadder: true));
        cur = lad;
      } else if (snk != null) {
        slides.add(SlHop(from: cur, to: snk, isLadder: false));
        cur = snk;
      } else {
        break;
      }
    }
    pos[turn] = cur;
    final won = cur == 100;
    return SlMove(
      roll: roll,
      startPos: start,
      steps: steps,
      overshoot: false,
      climbs: climbs,
      slides: slides,
      finalPos: cur,
      won: won,
      extraRoll: roll == 6 && !won,
    );
  }

  /// Player indices sorted for final standings: winner first, then by
  /// final square descending (RULES §8).
  List<int> standings(int winIdx) {
    final rest = [for (int i = 0; i < n; i++) if (i != winIdx) i]
      ..sort((a, b) => pos[b].compareTo(pos[a]));
    return [winIdx, ...rest];
  }
}

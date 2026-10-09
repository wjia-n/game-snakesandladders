import 'dart:math';

/// Snakes & Ladders engine — deterministic rules core.
/// Authoritative source: RULES.md. Fixed board, fixed turn order
/// (Red → Blue → Green → Yellow), roll-off for first player,
/// exact-100 finish, extra roll on 6, chained ladder/snake resolution.
class SlPlayer {
  final String name;
  final int colorIndex; // 0=Red, 1=Blue, 2=Green, 3=Yellow
  final bool isBot;
  const SlPlayer({required this.name, required this.colorIndex, this.isBot = false});
}

/// A ladder climb or snake slide event: from → to.
class SlHop {
  final int from;
  final int to;
  final bool isLadder;
  const SlHop({required this.from, required this.to, required this.isLadder});
  int get delta => (to - from).abs();
}

/// Outcome of applying one die roll for the current player.
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

class SlEngine {
  // Fixed ladder map (foot → top). RULES §2.
  static const ladders = <int, int>{
    1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100,
  };
  // Fixed snake map (head → tail). RULES §2.
  static const snakes = <int, int>{
    16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78,
  };

  /// Guard against infinite chained resolution (RULES §7).
  static const maxChain = 10;

  final List<SlPlayer> players;
  final List<int> pos; // 0 = off board, waiting to enter
  int turn = 0;
  int round = 1;

  SlEngine({required this.players}) : pos = List.filled(players.length, 0);

  int get n => players.length;
  SlPlayer get current => players[turn];

  /// Roll-off for first player (RULES §3): each player rolls once, highest
  /// starts; ties re-roll among tied players only. Returns the per-player
  /// rolls of the FINAL round (for display); sets [turn] to the starter.
  /// [onRound] is called with each round's rolls (for animation).
  List<int> rollOff(Random rand, {void Function(List<int> rolls, List<int> contenders)? onRound}) {
    var contenders = List<int>.generate(n, (i) => i);
    List<int> last = [];
    while (contenders.length > 1) {
      final rolls = [for (final _ in contenders) rand.nextInt(6) + 1];
      onRound?.call(rolls, List.of(contenders));
      last = rolls;
      final best = rolls.reduce(max);
      contenders = [for (int i = 0; i < contenders.length; i++) if (rolls[i] == best) contenders[i]];
      if (contenders.length == 1) break;
    }
    if (last.isEmpty) {
      final rolls = [rand.nextInt(6) + 1];
      onRound?.call(rolls, List.of(contenders));
      last = rolls;
    }
    turn = contenders.single;
    return last;
  }

  /// Applies [roll] for the current player. RULES §4:
  /// - pawn at 0 enters on the square equal to the roll;
  /// - overshoot (>100) → pawn stays, turn passes;
  /// - ladder feet / snake heads resolve immediately (chained, max 10);
  /// - rolling 6 grants one extra roll (not after a win).
  SlMove applyRoll(int roll) {
    final start = pos[turn];
    final target = start + roll;
    if (target > 100) {
      return SlMove(
        roll: roll, startPos: start, steps: const [],
        overshoot: true, climbs: const [], slides: const [],
        finalPos: start, won: false, extraRoll: false,
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

  /// Ends the current turn. If [keepTurn] (extra roll from a 6), the same
  /// player moves again; otherwise play passes clockwise (RULES §3).
  void endTurn({required bool keepTurn}) {
    if (!keepTurn) {
      turn = (turn + 1) % n;
      if (turn == 0) round++;
    }
  }

  /// Player indices sorted for final standings: winner first, then by
  /// final square descending (RULES §8).
  List<int> standings(int winner) {
    final rest = [for (int i = 0; i < n; i++) if (i != winner) i]
      ..sort((a, b) => pos[b].compareTo(pos[a]));
    return [winner, ...rest];
  }
}

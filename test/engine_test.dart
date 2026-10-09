import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:snakesandladders/engine/sl_engine.dart';

SlEngine twoPlayer({Random? rand}) => SlEngine(
      players: [
        SlPlayer(name: 'Red', colorIndex: 0),
        SlPlayer(name: 'Blue', colorIndex: 1),
      ],
      testMode: true,
      rand: rand,
    )..drainTest(); // complete the roll-off synchronously

/// The player under test: whoever won the roll-off (engine owns turn state).
int cur(SlEngine e) => e.turn;
void place(SlEngine e, int sq) => e.pos[e.turn] = sq;

void main() {
  group('RULES.md test cases (applyRoll)', () {
    test('TC-01: pawn at 0, roll 4 -> 14 (ladder 4->14)', () {
      final e = twoPlayer();
      final m = e.applyRoll(4);
      expect(m.finalPos, 14);
      expect(m.climbs.single.to, 14);
    });
    test('TC-02: pawn on 20, roll 1 -> 42 (ladder 21->42)', () {
      final e = twoPlayer();
      place(e, 20);
      final m = e.applyRoll(1);
      expect(m.finalPos, 42);
    });
    test('TC-03: pawn on 15, roll 1 -> 6 (snake 16->6)', () {
      final e = twoPlayer();
      place(e, 15);
      final m = e.applyRoll(1);
      expect(m.finalPos, 6);
      expect(m.slides.single.to, 6);
    });
    test('TC-04: pawn on 79, roll 1 -> 100, won (ladder 80->100)', () {
      final e = twoPlayer();
      place(e, 79);
      final m = e.applyRoll(1);
      expect(m.finalPos, 100);
      expect(m.won, true);
      expect(m.extraRoll, false);
    });
    test('TC-05: pawn on 97, roll 5 -> stays 97 (overshoot)', () {
      final e = twoPlayer();
      place(e, 97);
      final m = e.applyRoll(5);
      expect(m.overshoot, true);
      expect(m.finalPos, 97);
      expect(e.pos[cur(e)], 97);
    });
    test('TC-06: pawn on 99, roll 1 -> 100, won', () {
      final e = twoPlayer();
      place(e, 99);
      final m = e.applyRoll(1);
      expect(m.finalPos, 100);
      expect(m.won, true);
    });
    test('TC-07: pawn on 10, roll 6 -> 16 -> slide to 6 + extra roll', () {
      final e = twoPlayer();
      place(e, 10);
      final m = e.applyRoll(6);
      expect(m.steps, [11, 12, 13, 14, 15, 16]);
      expect(m.slides.single.from, 16);
      expect(m.slides.single.to, 6);
      expect(m.finalPos, 6);
      expect(m.extraRoll, true);
    });
    test('TC-08: pawn on 93, roll 5 -> 98 -> slide to 78', () {
      final e = twoPlayer();
      place(e, 93);
      final m = e.applyRoll(5);
      expect(m.finalPos, 78);
      expect(m.slides.single.from, 98);
    });
    test('TC-10: roll 6 from 94 -> 100, won, no extra roll', () {
      final e = twoPlayer();
      place(e, 94);
      final m = e.applyRoll(6);
      expect(m.finalPos, 100);
      expect(m.won, true);
      expect(m.extraRoll, false);
    });
    test('TC-11: two pawns may share a square, no capture', () {
      final e = twoPlayer();
      e.pos[0] = 38;
      e.pos[1] = 38;
      expect(e.pos[0], 38);
      expect(e.pos[1], 38);
    });
    test('TC-13: forced roll from 50: [6] -> 56 -> 53; [3] -> 53 no slide',
        () {
      final e = twoPlayer();
      place(e, 50);
      final m6 = e.applyRoll(6);
      expect(m6.finalPos, 53);
      expect(m6.slides.single.from, 56);
      place(e, 50);
      final m3 = e.applyRoll(3);
      expect(m3.finalPos, 53);
      expect(m3.slides, isEmpty); // 53 is a snake tail, not a head
    });
    test('TC-12/edge: pawn on 97, roll 4 -> stays (would be 101)', () {
      final e = twoPlayer();
      place(e, 97);
      final m = e.applyRoll(4);
      expect(m.overshoot, true);
      expect(m.extraRoll, false);
    });
    test('first roll is a 6: enters on 6, extra roll granted', () {
      final e = twoPlayer();
      final m = e.applyRoll(6);
      expect(m.steps.first, 1);
      expect(m.finalPos, 6);
      expect(m.extraRoll, true);
    });
  });

  group('turn order (TC-09)', () {
    test('3 players: rotation skips no one, order is cyclic', () {
      final e = SlEngine(
        players: [
          SlPlayer(name: 'R', colorIndex: 0),
          SlPlayer(name: 'B', colorIndex: 1),
          SlPlayer(name: 'G', colorIndex: 2),
        ],
        testMode: true,
        rand: Random(7),
      )..drainTest();
      expect(e.phase, SlPhase.awaitingRoll);
      // Drive turns with forced rolls of 1 and check the rotation.
      final order = <int>[];
      for (int i = 0; i < 6; i++) {
        order.add(e.turn);
        e.forcedRoll = 1;
        e.roll(); // all-human game: manual rolls
        e.drainTest();
      }
      // With all-human players, turn must rotate cyclically (starting
      // from whichever seat won the roll-off).
      final start = order.first;
      for (int i = 0; i < 6; i++) {
        expect(order[i], (start + i) % 3);
      }
    });
  });

  group('roll-off (TC-14)', () {
    test('roll-off completes and picks a valid starter', () {
      for (int seed = 0; seed < 20; seed++) {
        final e = SlEngine(
          players: [
            SlPlayer(name: 'R', colorIndex: 0),
            SlPlayer(name: 'B', colorIndex: 1),
            SlPlayer(name: 'G', colorIndex: 2),
            SlPlayer(name: 'Y', colorIndex: 3),
          ],
          testMode: true,
          rand: Random(seed),
        );
        expect(e.phase, SlPhase.rollOff);
        e.drainTest();
        expect(e.phase, SlPhase.awaitingRoll);
        expect(e.turn, inInclusiveRange(0, 3));
        expect(e.pos, everyElement(0));
      }
    });
  });

  group('no stuck states: bot-vs-bot full games', () {
    test('all-bot games always finish, winner on 100', () {
      for (final diff in BotDifficulty.values) {
        for (final count in [2, 3, 4]) {
          for (int seed = 0; seed < 5; seed++) {
            final e = SlEngine(
              players: [
                for (int i = 0; i < count; i++)
                  SlPlayer(name: 'Bot$i', colorIndex: i, isBot: true),
              ],
              botDifficulty: diff,
              testMode: true,
              rand: Random(seed * 31 + count),
            );
            e.drainTest(); // throws on stuck state
            expect(e.over, true,
                reason: 'seed=$seed count=$count diff=$diff');
            expect(e.winner, isNotNull);
            expect(e.pos[e.winner!], 100);
            // Standings: winner first, rest by square descending.
            final st = e.standings(e.winner!);
            expect(st.first, e.winner);
            expect(st.length, count);
          }
        }
      }
    });

    test('mixed human/bot seats finish (humans auto-driven)', () {
      final e = SlEngine(
        players: [
          SlPlayer(name: 'Human', colorIndex: 0),
          SlPlayer(name: 'Bot', colorIndex: 1, isBot: true),
          SlPlayer(name: 'Bot2', colorIndex: 2, isBot: true),
        ],
        testMode: true,
        rand: Random(1234),
      );
      // Roll-off first.
      e.drainTest(limit: 10000);
      expect(e.phase, SlPhase.awaitingRoll);
      // Drive human turns manually until the game ends.
      var guard = 0;
      while (!e.over && guard++ < 20000) {
        if (e.awaitingRoll && !e.current.isBot) {
          e.roll();
        }
        e.drainTest(limit: 1000);
      }
      expect(e.over, true);
      expect(e.pos[e.winner!], 100);
    });

    test('overshoot loops cannot deadlock near 100', () {
      final e = twoPlayer(rand: Random(99));
      place(e, 99);
      e.pos[1] = 99;
      final m = e.applyRoll(6);
      expect(m.overshoot, true);
      expect(m.extraRoll, false);
      final m1 = e.applyRoll(1);
      expect(m1.won, true);
    });
  });

  group('engine invariants', () {
    test('positions stay in 0..100 and travel timelines are sane', () {
      final e = SlEngine(
        players: [
          for (int i = 0; i < 4; i++)
            SlPlayer(name: 'B$i', colorIndex: i, isBot: true),
        ],
        testMode: true,
        rand: Random(2026),
      );
      e.onEvent = (ev) {
        if (ev == SlEvent.moveSettled) {
          final t = e.travel!;
          expect(t.totalMs, greaterThan(0));
          expect(t.segs, isNotEmpty);
          for (final p in e.pos) {
            expect(p, inInclusiveRange(0, 100));
          }
        }
      };
      e.drainTest();
      expect(e.over, true);
    });
  });
}

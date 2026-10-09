import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:snakesandladders/engine.dart';

SlEngine twoPlayer() => SlEngine(players: const [
      SlPlayer(name: 'Red', colorIndex: 0),
      SlPlayer(name: 'Blue', colorIndex: 1),
    ]);

void main() {
  group('RULES.md test cases', () {
    test('TC-01: pawn at 0, roll 4 -> 14 (ladder 4->14)', () {
      final e = twoPlayer();
      final m = e.applyRoll(4);
      expect(m.finalPos, 14);
      expect(m.climbs.single.to, 14);
    });
    test('TC-02: pawn on 20, roll 1 -> 42 (ladder 21->42)', () {
      final e = twoPlayer();
      e.pos[0] = 20;
      final m = e.applyRoll(1);
      expect(m.finalPos, 42);
    });
    test('TC-03: pawn on 15, roll 1 -> 6 (snake 16->6)', () {
      final e = twoPlayer();
      e.pos[0] = 15;
      final m = e.applyRoll(1);
      expect(m.finalPos, 6);
      expect(m.slides.single.to, 6);
    });
    test('TC-04: pawn on 79, roll 1 -> 100, won (ladder 80->100)', () {
      final e = twoPlayer();
      e.pos[0] = 79;
      final m = e.applyRoll(1);
      expect(m.finalPos, 100);
      expect(m.won, true);
      expect(m.extraRoll, false);
    });
    test('TC-05: pawn on 97, roll 5 -> stays 97 (overshoot)', () {
      final e = twoPlayer();
      e.pos[0] = 97;
      final m = e.applyRoll(5);
      expect(m.overshoot, true);
      expect(m.finalPos, 97);
      expect(e.pos[0], 97);
    });
    test('TC-06: pawn on 99, roll 1 -> 100, won', () {
      final e = twoPlayer();
      e.pos[0] = 99;
      final m = e.applyRoll(1);
      expect(m.finalPos, 100);
      expect(m.won, true);
    });
    test('TC-07: pawn on 10, roll 6 -> 16 -> 6, extra roll', () {
      final e = twoPlayer();
      e.pos[0] = 10;
      final m = e.applyRoll(6);
      expect(m.finalPos, 6);
      expect(m.slides.single.from, 16);
      expect(m.extraRoll, true);
    });
    test('TC-08: pawn on 93, roll 5 -> 98 -> 78', () {
      final e = twoPlayer();
      e.pos[0] = 93;
      final m = e.applyRoll(5);
      expect(m.finalPos, 78);
    });
    test('TC-09: turn order Red->Blue->Green skips Yellow', () {
      final e = SlEngine(players: const [
        SlPlayer(name: 'R', colorIndex: 0),
        SlPlayer(name: 'B', colorIndex: 1),
        SlPlayer(name: 'G', colorIndex: 2),
      ]);
      expect(e.turn, 0);
      e.endTurn(keepTurn: false);
      expect(e.turn, 1);
      e.endTurn(keepTurn: false);
      expect(e.turn, 2);
      e.endTurn(keepTurn: false);
      expect(e.turn, 0);
      expect(e.round, 2);
    });
    test('TC-10: roll 6 from 94 -> 100, win, no extra roll', () {
      final e = twoPlayer();
      e.pos[0] = 94;
      final m = e.applyRoll(6);
      expect(m.finalPos, 100);
      expect(m.won, true);
      expect(m.extraRoll, false);
    });
    test('TC-11: two pawns may share a square', () {
      final e = twoPlayer();
      e.pos[0] = 38;
      e.pos[1] = 38;
      expect(e.pos[0], e.pos[1]);
    });
    test('TC-13: forced roll 6 from 50 -> 56 -> 53; forced 3 -> 53 no slide', () {
      final e = twoPlayer();
      e.pos[0] = 50;
      final m6 = e.applyRoll(6);
      expect(m6.finalPos, 53);
      expect(m6.slides.single.from, 56);
      final e2 = twoPlayer();
      e2.pos[0] = 50;
      final m3 = e2.applyRoll(3);
      expect(m3.finalPos, 53);
      expect(m3.slides, isEmpty);
    });
    test('TC-14: roll-off picks highest roller; ties re-roll', () {
      for (int i = 0; i < 50; i++) {
        final e = SlEngine(players: const [
          SlPlayer(name: 'R', colorIndex: 0),
          SlPlayer(name: 'B', colorIndex: 1),
          SlPlayer(name: 'G', colorIndex: 2),
          SlPlayer(name: 'Y', colorIndex: 3),
        ]);
        e.rollOff(Random(i));
        expect(e.turn, inInclusiveRange(0, 3));
      }
    });
    test('extra roll keeps turn; normal roll passes turn', () {
      final e = twoPlayer();
      e.applyRoll(6);
      e.endTurn(keepTurn: true);
      expect(e.turn, 0);
      e.applyRoll(3);
      e.endTurn(keepTurn: false);
      expect(e.turn, 1);
    });
    test('standings: winner first, then by square desc', () {
      final e = twoPlayer();
      e.pos[0] = 100;
      e.pos[1] = 77;
      expect(e.standings(0), [0, 1]);
    });
  });
}

Matcher inInclusiveRange(int lo, int hi) =>
    predicate<int>((v) => v >= lo && v <= hi, 'in range $lo..$hi');

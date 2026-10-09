import 'package:shared_preferences/shared_preferences.dart';

/// Persisted parlour records for Snakes & Ladders (local only).
class SlSettings {
  SlSettings._();
  static final SlSettings instance = SlSettings._();

  /// Wins per pawn colour index (0=Red, 1=Blue, 2=Green, 3=Yellow).
  List<int> wins = [0, 0, 0, 0];

  /// Biggest single-turn ladder climb (squares gained).
  int biggestClimb = 0;

  /// Longest snake slide suffered (squares lost).
  int longestSlide = 0;

  /// Games finished (not abandoned).
  int gamesPlayed = 0;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final p = await SharedPreferences.getInstance();
    wins = [for (int i = 0; i < 4; i++) p.getInt('sl_wins_$i') ?? 0];
    biggestClimb = p.getInt('sl_biggest_climb') ?? 0;
    longestSlide = p.getInt('sl_longest_slide') ?? 0;
    gamesPlayed = p.getInt('sl_games_played') ?? 0;
    _ready = true;
  }

  Future<void> recordWin(int colorIndex) async {
    final p = await SharedPreferences.getInstance();
    wins[colorIndex]++;
    gamesPlayed++;
    await p.setInt('sl_wins_$colorIndex', wins[colorIndex]);
    await p.setInt('sl_games_played', gamesPlayed);
  }

  Future<void> recordClimb(int squares) async {
    if (squares <= biggestClimb) return;
    biggestClimb = squares;
    await (await SharedPreferences.getInstance()).setInt('sl_biggest_climb', squares);
  }

  Future<void> recordSlide(int squares) async {
    if (squares <= longestSlide) return;
    longestSlide = squares;
    await (await SharedPreferences.getInstance()).setInt('sl_longest_slide', squares);
  }
}

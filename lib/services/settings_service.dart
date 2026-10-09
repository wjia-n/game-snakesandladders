import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/storybook_themes.dart';

/// Persisted settings + stats for Snakes & Ladders. Survives app restarts.
///
/// Stores: audio toggles, player names (4 slots), theme/appearance choices
/// (incl. custom theme colors), game-mode setup (players, bots, difficulty),
/// Pro unlock state, and lifetime stats.
class StorySettings extends ChangeNotifier {
  static const _kMusic = 'snakes_music_on';
  static const _kSfx = 'snakes_sfx_on';
  static const _kVolume = 'snakes_volume';
  static const _kPlayers = 'snakes_player_count';
  static const _kDifficulty = 'snakes_bot_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kNames = 'snakes_player_names'; // StringList, 4 entries
  static const _kTheme = 'snakes_theme_id';
  static const _kTokenShape = 'snakes_token_shape';
  static const _kDiceStyle = 'snakes_dice_style';
  static const _kWins = 'snakes_wins';
  static const _kGames = 'snakes_games_played';
  static const _kClimb = 'snakes_biggest_climb';
  static const _kSlide = 'snakes_longest_slide';
  static const _kIsPro = 'snakes_is_pro';
  static const _kCustomPrefix = 'snakes_custom_';

  static const defaultNames = [
    'Lady Beatrice',
    'Master Edwin',
    'Captain Algernon',
    'Miss Penelope',
  ];

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int playerCount = 2;
  int difficulty = 1; // medium default
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int tokenShape = 0;
  int diceStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int biggestClimb = 0;
  int longestSlide = 0;
  bool isPro = false;

  /// Seats (player indices) that are bots. At least one human always plays.
  List<int> botSeats = [1];

  /// Custom theme colors (ARGB ints). Defaults mirror the Classic Storybook.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'parchment': 0xFFF1E3C3,
    'parchmentDeep': 0xFFE3CFA4,
    'woodDark': 0xFF6B4A2F,
    'woodMid': 0xFFA4713F,
    'ink': 0xFF4A3220,
    'inkSoft': 0xFF7A5C3E,
    'accent': 0xFFB08D3E,
    'accentLight': 0xFFD4A93C,
    'accentDark': 0xFF8A6B2A,
    'goldLeaf': 0xFFD4A93C,
    'snakeGreen': 0xFF4E6B34,
    'pc0': 0xFFB3402E,
    'pc1': 0xFF2E5F8A,
    'pc2': 0xFF3E7A3E,
    'pc3': 0xFFD9A62E,
  };

  /// Builds the user-designed custom theme from stored colors.
  StoryThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return StoryThemeDef(
      id: 'custom',
      name: 'My Creation',
      parchment: c('parchment'),
      parchmentDeep: c('parchmentDeep'),
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      ink: c('ink'),
      inkSoft: c('inkSoft'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      goldLeaf: c('goldLeaf'),
      snakeGreen: c('snakeGreen'),
      pawnColors: [c('pc0'), c('pc1'), c('pc2'), c('pc3')],
      playerColorNames: const ['One', 'Two', 'Three', 'Four'],
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    playerCount = (p.getInt(_kPlayers) ?? 2).clamp(2, 4);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    final names = p.getStringList(_kNames);
    if (names != null && names.length == 4) {
      playerNames = [
        for (int i = 0; i < 4; i++)
          names[i].trim().isEmpty ? defaultNames[i] : names[i].trim()
      ];
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    tokenShape = (p.getInt(_kTokenShape) ?? 0).clamp(0, 11);
    diceStyle = (p.getInt(_kDiceStyle) ?? 0).clamp(0, 5);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    biggestClimb = p.getInt(_kClimb) ?? 0;
    longestSlide = p.getInt(_kSlide) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    // Restore bot seats (stored as a bitmask in player count key legacy —
    // default to seat 1 as bot for 2-player games).
    final stored = p.getStringList('snakes_bot_seats');
    if (stored != null) {
      final seats = [
        for (final s in stored)
          int.tryParse(s) ?? -1
      ].where((s) => s >= 0 && s < playerCount).toList();
      if (seats.isNotEmpty && seats.length < playerCount) botSeats = seats;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kPlayers, playerCount);
    await p.setInt(_kDifficulty, difficulty);
    await p.setStringList(_kNames, playerNames);
    await p.setStringList(
        'snakes_bot_seats', [for (final s in botSeats) '$s']);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kTokenShape, tokenShape);
    await p.setInt(_kDiceStyle, diceStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kClimb, biggestClimb);
    await p.setInt(_kSlide, longestSlide);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (StoryThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (TokenShapes.isPro(tokenShape)) {
      tokenShape = 0;
      changed = true;
    }
    if (DiceStyles.isPro(diceStyle)) {
      diceStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Full mode setup: [players] 2..4 humans+bots, [difficulty] 0/1/2,
  /// [botSeats] lists player indices that are bots.
  Future<void> setSetup({
    required int players,
    required List<int> botSeats,
    required int difficulty,
  }) async {
    playerCount = players.clamp(2, 4);
    this.botSeats = [
      for (final s in botSeats)
        if (s >= 0 && s < playerCount) s
    ];
    // Never allow all seats to be bots — at least one human must play.
    if (this.botSeats.length >= playerCount) {
      this.botSeats = this.botSeats.sublist(0, playerCount - 1);
    }
    if (this.botSeats.isEmpty) {
      // Default: last seat is the clockwork rival.
      this.botSeats = [playerCount - 1];
    }
    this.difficulty = difficulty.clamp(0, 2);
    // Hard mode is a Pro feature.
    if (!isPro && this.difficulty > 1) this.difficulty = 1;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 3) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes require Pro; silently ignore otherwise (UI shows lock).
    if (!isPro && StoryThemes.isProTheme(id)) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTokenShape(int v) async {
    v = v.clamp(0, TokenShapes.names.length - 1);
    if (!isPro && TokenShapes.isPro(v)) return;
    tokenShape = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDiceStyle(int v) async {
    v = v.clamp(0, DiceStyles.names.length - 1);
    if (!isPro && DiceStyles.isPro(v)) return;
    diceStyle = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished game.
  Future<void> recordGame({
    required bool humanWon,
    required int biggestClimb,
    required int longestSlide,
  }) async {
    gamesPlayed++;
    if (humanWon) wins++;
    if (biggestClimb > this.biggestClimb) this.biggestClimb = biggestClimb;
    if (longestSlide > this.longestSlide) this.longestSlide = longestSlide;
    notifyListeners();
    await _save();
  }
}

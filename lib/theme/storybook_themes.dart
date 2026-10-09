import 'package:flutter/material.dart';

/// Theme, token-shape and dice-style catalog for Snakes & Ladders.
///
/// Every theme stays inside the vintage storybook material world (aged
/// parchment, carved wood, brass, ivory, hand-painted serpent greens) — the
/// variety comes from different woods, parchment washes, metal accents and
/// jewel-tone pawn paints.
class StoryThemeDef {
  final String id;
  final String name;
  final Color parchment;
  final Color parchmentDeep;
  final Color woodDark;
  final Color woodMid;
  final Color ink;
  final Color inkSoft;
  final Color accent; // brass / copper / silver …
  final Color accentLight;
  final Color accentDark;
  final Color goldLeaf;
  final Color snakeGreen;
  final List<Color> pawnColors;
  final List<String> playerColorNames;

  const StoryThemeDef({
    required this.id,
    required this.name,
    required this.parchment,
    required this.parchmentDeep,
    required this.woodDark,
    required this.woodMid,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.goldLeaf,
    required this.snakeGreen,
    required this.pawnColors,
    required this.playerColorNames,
  });
}

class StoryThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'agedoak',
    'goldenhour',
    'foresttale',
  ];

  static const List<StoryThemeDef> all = [
    // ---- FREE ----
    StoryThemeDef(
      id: 'classic',
      name: 'Storybook Classic',
      parchment: Color(0xFFF1E3C3),
      parchmentDeep: Color(0xFFE3CFA4),
      woodDark: Color(0xFF6B4A2F),
      woodMid: Color(0xFFA4713F),
      ink: Color(0xFF4A3220),
      inkSoft: Color(0xFF7A5C3E),
      accent: Color(0xFFB08D3E),
      accentLight: Color(0xFFD4A93C),
      accentDark: Color(0xFF8A6B2A),
      goldLeaf: Color(0xFFD4A93C),
      snakeGreen: Color(0xFF4E6B34),
      pawnColors: [
        Color(0xFFB3402E),
        Color(0xFF2E5F8A),
        Color(0xFF3E7A3E),
        Color(0xFFD9A62E),
      ],
      playerColorNames: ['Crimson', 'Indigo', 'Moss', 'Honey'],
    ),
    StoryThemeDef(
      id: 'agedoak',
      name: 'Aged Oak',
      parchment: Color(0xFFEAD9B8),
      parchmentDeep: Color(0xFFDCC493),
      woodDark: Color(0xFF4E331F),
      woodMid: Color(0xFF7A5230),
      ink: Color(0xFF3A2513),
      inkSoft: Color(0xFF6E5335),
      accent: Color(0xFF9A7B34),
      accentLight: Color(0xFFC9A44E),
      accentDark: Color(0xFF6E5722),
      goldLeaf: Color(0xFFC9A44E),
      snakeGreen: Color(0xFF42592C),
      pawnColors: [
        Color(0xFFA03123),
        Color(0xFF274E73),
        Color(0xFF356635),
        Color(0xFFB98A24),
      ],
      playerColorNames: ['Rust', 'Slate', 'Fern', 'Amber'],
    ),
    StoryThemeDef(
      id: 'goldenhour',
      name: 'Golden Hour',
      parchment: Color(0xFFF7E8C8),
      parchmentDeep: Color(0xFFF0D49A),
      woodDark: Color(0xFF7A5A24),
      woodMid: Color(0xFF9A7534),
      ink: Color(0xFF54401E),
      inkSoft: Color(0xFF8A6E42),
      accent: Color(0xFFB8860B),
      accentLight: Color(0xFFDEB84E),
      accentDark: Color(0xFF8A6508),
      goldLeaf: Color(0xFFDEB84E),
      snakeGreen: Color(0xFF5A7038),
      pawnColors: [
        Color(0xFFC0392B),
        Color(0xFF1F618D),
        Color(0xFF229954),
        Color(0xFF7D3C98),
      ],
      playerColorNames: ['Poppy', 'River', 'Clover', 'Plum'],
    ),
    StoryThemeDef(
      id: 'foresttale',
      name: 'Forest Tale',
      parchment: Color(0xFFEEE6C8),
      parchmentDeep: Color(0xFFDCD0A4),
      woodDark: Color(0xFF3E4A2E),
      woodMid: Color(0xFF5A6A42),
      ink: Color(0xFF2E3A20),
      inkSoft: Color(0xFF5A6644),
      accent: Color(0xFF8A8A3E),
      accentLight: Color(0xFFB8B86A),
      accentDark: Color(0xFF5E5E26),
      goldLeaf: Color(0xFFC9A44E),
      snakeGreen: Color(0xFF3A5226),
      pawnColors: [
        Color(0xFFB3402E),
        Color(0xFFD9A62E),
        Color(0xFF2E5F8A),
        Color(0xFF8E44AD),
      ],
      playerColorNames: ['Berry', 'Wheat', 'Pond', 'Grape'],
    ),
    // ---- PRO ----
    StoryThemeDef(
      id: 'rosewood',
      name: 'Rosewood Manor',
      parchment: Color(0xFFF0DFC0),
      parchmentDeep: Color(0xFFE0C69A),
      woodDark: Color(0xFF4A2430),
      woodMid: Color(0xFF6E3644),
      ink: Color(0xFF381820),
      inkSoft: Color(0xFF6E4A52),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      goldLeaf: Color(0xFFE09E5A),
      snakeGreen: Color(0xFF4E6B34),
      pawnColors: [
        Color(0xFFD4AC0D),
        Color(0xFF2E86C1),
        Color(0xFF229954),
        Color(0xFFAF601A),
      ],
      playerColorNames: ['Topaz', 'Steel', 'Leaf', 'Caramel'],
    ),
    StoryThemeDef(
      id: 'seaside',
      name: 'Seaside Story',
      parchment: Color(0xFFEFE6D0),
      parchmentDeep: Color(0xFFDED0AE),
      woodDark: Color(0xFF2E4A5A),
      woodMid: Color(0xFF486A7E),
      ink: Color(0xFF24363F),
      inkSoft: Color(0xFF5A7078),
      accent: Color(0xFF8AA8B8),
      accentLight: Color(0xFFBFD4DE),
      accentDark: Color(0xFF5E7888),
      goldLeaf: Color(0xFFD4A93C),
      snakeGreen: Color(0xFF3E6B5A),
      pawnColors: [
        Color(0xFFC0392B),
        Color(0xFFD4AC0D),
        Color(0xFF1E8449),
        Color(0xFF8E44AD),
      ],
      playerColorNames: ['Coral', 'Sand', 'Kelp', 'Shell'],
    ),
    StoryThemeDef(
      id: 'candlelight',
      name: 'Candlelight',
      parchment: Color(0xFFE8D3AC),
      parchmentDeep: Color(0xFFD4B684),
      woodDark: Color(0xFF2E1F14),
      woodMid: Color(0xFF4A3320),
      ink: Color(0xFFF1E3C3),
      inkSoft: Color(0xFFC9B586),
      accent: Color(0xFFD4A93C),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      goldLeaf: Color(0xFFF3DC8E),
      snakeGreen: Color(0xFF6E8B4A),
      pawnColors: [
        Color(0xFFE74C3C),
        Color(0xFF5DADE2),
        Color(0xFF58D68D),
        Color(0xFFF5B041),
      ],
      playerColorNames: ['Ember', 'Moon', 'Jade', 'Flame'],
    ),
    StoryThemeDef(
      id: 'autumn',
      name: 'Autumn Fable',
      parchment: Color(0xFFF2E0BC),
      parchmentDeep: Color(0xFFE4C48E),
      woodDark: Color(0xFF5A2A1A),
      woodMid: Color(0xFF7C3F24),
      ink: Color(0xFF3E1F10),
      inkSoft: Color(0xFF7A4E32),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFDFB06A),
      accentDark: Color(0xFF7E4F22),
      goldLeaf: Color(0xFFDFB06A),
      snakeGreen: Color(0xFF5A5A2E),
      pawnColors: [
        Color(0xFF922B21),
        Color(0xFF7E5109),
        Color(0xFF1E8449),
        Color(0xFF6E2C00),
      ],
      playerColorNames: ['Cider', 'Ochre', 'Pine', 'Bark'],
    ),
    StoryThemeDef(
      id: 'midnight',
      name: 'Midnight Tales',
      parchment: Color(0xFFE4D6BC),
      parchmentDeep: Color(0xFFCAB98E),
      woodDark: Color(0xFF1C2438),
      woodMid: Color(0xFF2C3A55),
      ink: Color(0xFFF2EEE4),
      inkSoft: Color(0xFFB8B49A),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      goldLeaf: Color(0xFFE8CE7A),
      snakeGreen: Color(0xFF6E8B4A),
      pawnColors: [
        Color(0xFFD64545),
        Color(0xFF4A90D9),
        Color(0xFF3FB97F),
        Color(0xFFE0A83C),
      ],
      playerColorNames: ['Candle', 'Moonstone', 'Fern', 'Lantern'],
    ),
    StoryThemeDef(
      id: 'meadow',
      name: 'Spring Meadow',
      parchment: Color(0xFFF6F0DC),
      parchmentDeep: Color(0xFFE8DCC0),
      woodDark: Color(0xFF5A6E3A),
      woodMid: Color(0xFF7A8E52),
      ink: Color(0xFF3A4426),
      inkSoft: Color(0xFF6E784E),
      accent: Color(0xFF9AA83E),
      accentLight: Color(0xFFC4D06A),
      accentDark: Color(0xFF6E7A26),
      goldLeaf: Color(0xFFD4A93C),
      snakeGreen: Color(0xFF3E6B34),
      pawnColors: [
        Color(0xFFC0392B),
        Color(0xFF2471A3),
        Color(0xFFD4AC0D),
        Color(0xFF8E44AD),
      ],
      playerColorNames: ['Tulip', 'Sky', 'Daisy', 'Violet'],
    ),
    StoryThemeDef(
      id: 'caravan',
      name: 'Desert Caravan',
      parchment: Color(0xFFF4E4C2),
      parchmentDeep: Color(0xFFE8CC94),
      woodDark: Color(0xFF6E4A2E),
      woodMid: Color(0xFF8E6238),
      ink: Color(0xFF4A3018),
      inkSoft: Color(0xFF8A6A44),
      accent: Color(0xFFB8860B),
      accentLight: Color(0xFFE0B84E),
      accentDark: Color(0xFF7E5E08),
      goldLeaf: Color(0xFFE0B84E),
      snakeGreen: Color(0xFF6B6B34),
      pawnColors: [
        Color(0xFFA93226),
        Color(0xFF1A5276),
        Color(0xFF1E8449),
        Color(0xFF7D6608),
      ],
      playerColorNames: ['Spice', 'Oasis', 'Palm', 'Dune'],
    ),
    StoryThemeDef(
      id: 'hearth',
      name: 'Winter Hearth',
      parchment: Color(0xFFF8F2E4),
      parchmentDeep: Color(0xFFEAE0C8),
      woodDark: Color(0xFF3A3A42),
      woodMid: Color(0xFF54545E),
      ink: Color(0xFF2A2A32),
      inkSoft: Color(0xFF6E6E78),
      accent: Color(0xFFB08D3E),
      accentLight: Color(0xFFDCC06A),
      accentDark: Color(0xFF7E6528),
      goldLeaf: Color(0xFFDCC06A),
      snakeGreen: Color(0xFF4A6B5A),
      pawnColors: [
        Color(0xFFB3402E),
        Color(0xFF2E5F8A),
        Color(0xFF3E7A3E),
        Color(0xFF8E44AD),
      ],
      playerColorNames: ['Holly', 'Frost', 'Pine', 'Plum'],
    ),
    StoryThemeDef(
      id: 'library',
      name: 'Royal Library',
      parchment: Color(0xFFF0E2C4),
      parchmentDeep: Color(0xFFE2CC9E),
      woodDark: Color(0xFF3A1420),
      woodMid: Color(0xFF5A2230),
      ink: Color(0xFF2E0E16),
      inkSoft: Color(0xFF6E4450),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      goldLeaf: Color(0xFFF3DC8E),
      snakeGreen: Color(0xFF4E6B34),
      pawnColors: [
        Color(0xFFD4AC0D),
        Color(0xFF7D3C98),
        Color(0xFF1E8449),
        Color(0xFF2471A3),
      ],
      playerColorNames: ['Crown', 'Amethyst', 'Jade', 'Teal'],
    ),
  ];

  static StoryThemeDef byId(String id, {StoryThemeDef? custom}) {
    if (id == 'custom') {
      return custom ?? all.first;
    }
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Token piece styles. 0-3 = FREE, 4+ = PRO.
class TokenShapes {
  static const names = [
    'Classic Pawn',
    'Wooden Orb',
    'Facet Gem',
    'Marble',
    'Star',
    'Crown',
    'Shield',
    'Acorn',
    'Leaf',
    'Coin',
    'Shell',
    'Mushroom',
  ];
  static const descriptions = [
    'Hand-carved pawn silhouette',
    'Turned wooden orb',
    'Cut-gemstone token',
    'Swirled glass marble',
    'Five-point brass star',
    'Jeweled crown token',
    'Enamel heraldic shield',
    'Carved oak acorn',
    'Painted wooden leaf',
    'Minted brass coin',
    'Scallop shell carving',
    'Storybook toadstool',
  ];

  /// Indices free players may use.
  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;
}

/// Dice styles. 0-1 = FREE, 2+ = PRO.
class DiceStyles {
  static const names = [
    'Ivory Classic',
    'Brass Noble',
    'Oak',
    'Marble Vein',
    'Obsidian',
    'Copper Rose',
  ];
  static const descriptions = [
    'Cold-cast ivory, burned-in pips',
    'Dark bronze die, brass pips',
    'Oiled oak die, burned pips',
    'White marble, slate veins',
    'Black glass, silver pips',
    'Rose copper, dark pips',
  ];

  /// Styles free players may use.
  static const freeCount = 2;
  static bool isPro(int index) => index >= freeCount;
}

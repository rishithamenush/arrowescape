import 'package:flutter/material.dart';

import 'levels.dart';

/// Levels per section (world).
const int kSectionSize = 15;

int get kSectionCount => (kLevels.length / kSectionSize).ceil();

/// A themed group of consecutive levels — a "world" on the worlds screen.
class GameSection {
  const GameSection(this.index);

  final int index;

  int get start => index * kSectionSize;
  int get count => (start + kSectionSize <= kLevels.length)
      ? kSectionSize
      : kLevels.length - start;
  int get end => start + count - 1;

  // A unique, themed name for every world.
  static const List<String> _names = [
    'Candy Town',
    'Gummy Grove',
    'Choco Cliffs',
    'Berry Bay',
    'Minty Meadow',
    'Lollipop Lane',
    'Caramel Cove',
    'Bubble Banks',
    'Sherbet Springs',
    'Frosting Fields',
    'Marshmallow Marsh',
    'Jellybean Junction',
    'Cupcake Canyon',
    'Peppermint Peak',
    'Toffee Trail',
    'Sugarplum Sands',
    'Fudge Forest',
    'Licorice Lagoon',
    'Honeycomb Hills',
    'Cotton Cloud',
    'Macaron Mesa',
    'Truffle Tundra',
    'Sprinkle Shores',
    'Nougat Nook',
    'Donut Delta',
    'Waffle Woods',
    'Custard Caverns',
    'Praline Prairie',
    'Sorbet Summit',
    'Brittle Bluff',
    'Gumdrop Gully',
    'Meringue Mount',
    'Butterscotch Bend',
    'Pudding Plains',
    'Taffy Town',
    'Eclair Estuary',
    'Pretzel Pass',
    'Vanilla Valley',
    'Cocoa Crater',
    'Bonbon Beach',
    'Lemonade Lake',
    'Pixie Pop Park',
    'Jelly Jungle',
    'Cocoa Coast',
    'Sundae Slopes',
    'Raspberry Reef',
    'Cinnamon City',
    'Marzipan Marsh',
    'Glaze Glacier',
    'Sugar Skies',
    'Wafer Wharf',
    'Cobbler Crossing',
    'Parfait Point',
    'Mochi Mountain',
    'Twist Tower',
    'Drizzle Den',
    'Frappe Falls',
    'Biscuit Basin',
    'Gelato Gardens',
    'Sprinkle Summit',
    'Caramel Keys',
    'Berry Burrow',
    'Choco Harbor',
    'Minty Marina',
    'Bubblegum Bluff',
    'Sweet Citadel',
    "Rainbow's End",
    'Candy Kingdom',
    'Sugar Galaxy',
    'Final Frosting',
  ];

  // One emoji per world (paired with the names above).
  static const List<String> _emojis = [
    '🍬', '🐻', '🍫', '🫐', '🌿', '🍭', '🍮', '🫧', '🍧', '🧁', //
    '☁️', '🫘', '🧁', '🥁', '🍯', '🍇', '🌲', '🌊', '🍯', '⛅', //
    '🍪', '🍫', '🎉', '🥜', '🍩', '🧇', '🍮', '🌾', '🍨', '🪨', //
    '🟢', '⛰️', '🧈', '🍮', '🍭', '🥐', '🥨', '🌼', '🌋', '🏖️', //
    '🍋', '✨', '🍮', '🌊', '🍨', '🫐', '🏙️', '🌰', '🧊', '🌈', //
    '🧇', '🥧', '🍨', '🍡', '🌀', '🍯', '🥤', '🍪', '🍨', '⛰️', //
    '🗝️', '🍓', '⚓', '⛵', '🎈', '🏰', '🌈', '👑', '🌌', '🏁', //
  ];

  String get name =>
      index < _names.length ? _names[index] : 'Sweet Spot ${index + 1}';

  String get emoji => index < _emojis.length ? _emojis[index] : '🍬';

  /// Each world gets its own hue. The golden-angle step (137.508°) spreads
  /// consecutive worlds far apart on the colour wheel, so neighbouring cards
  /// look totally different while every world stays a vivid candy tone.
  double get _hue => (index * 137.508) % 360;

  /// Top→bottom card gradient: a bright tint into a saturated base of the hue.
  List<Color> get gradient => [
    HSLColor.fromAHSL(1, _hue, 0.82, 0.72).toColor(),
    HSLColor.fromAHSL(1, _hue, 0.85, 0.55).toColor(),
  ];

  /// A deeper shade of the same hue, used for the card's drop shadow / accents.
  Color get shadow => HSLColor.fromAHSL(1, _hue, 0.70, 0.42).toColor();
}

List<GameSection> buildSections() => [
  for (var i = 0; i < kSectionCount; i++) GameSection(i),
];

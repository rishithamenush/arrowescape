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

  static const List<List<Color>> _grads = [
    [Color(0xFFFF9EC1), Color(0xFFFF5C97)],
    [Color(0xFFFFD76B), Color(0xFFFF9A3D)],
    [Color(0xFF7FE0F0), Color(0xFF2FB6D6)],
    [Color(0xFF9BE8B5), Color(0xFF3DDC84)],
    [Color(0xFFCDAEFF), Color(0xFF9B6BFF)],
    [Color(0xFF9BE8F5), Color(0xFF3EC8E0)],
  ];

  static const List<Color> _shadows = [
    Color(0xFFD62F76),
    Color(0xFFD77A1E),
    Color(0xFF1F8FB0),
    Color(0xFF1EA65C),
    Color(0xFF6E3FC4),
    Color(0xFF1F96AC),
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
  List<Color> get gradient => _grads[index % _grads.length];
  Color get shadow => _shadows[index % _shadows.length];
}

List<GameSection> buildSections() => [
  for (var i = 0; i < kSectionCount; i++) GameSection(i),
];

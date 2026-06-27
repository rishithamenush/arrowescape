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

  static const List<String> _emojis = [
    '🍬',
    '🐻',
    '🍫',
    '🫐',
    '🌿',
    '🍭',
    '🍮',
    '🫧',
    '🍧',
    '🧁',
  ];

  String get name {
    final base = _names[index % _names.length];
    final cycle = index ~/ _names.length;
    return cycle == 0 ? base : '$base ${cycle + 1}';
  }

  String get emoji => _emojis[index % _emojis.length];
  List<Color> get gradient => _grads[index % _grads.length];
  Color get shadow => _shadows[index % _shadows.length];
}

List<GameSection> buildSections() => [
  for (var i = 0; i < kSectionCount; i++) GameSection(i),
];

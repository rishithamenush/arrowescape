import 'arrow.dart';

/// A single puzzle definition.
class LevelModel {
  final int id;
  final int rows;
  final int cols;
  final List<ArrowModel> arrows;

  /// Move target used for the second star.
  final int targetMoves;

  const LevelModel({
    required this.id,
    required this.rows,
    required this.cols,
    required this.arrows,
    required this.targetMoves,
  });

  /// Returns a fresh deep copy of the arrows so the board can mutate freely
  /// without touching the original level definition.
  List<ArrowModel> freshArrows() =>
      arrows.map((a) => a.copyWith()).toList(growable: true);

  factory LevelModel.fromJson(Map<String, dynamic> json) => LevelModel(
    id: json['id'] as int,
    rows: json['rows'] as int,
    cols: json['cols'] as int,
    targetMoves: json['targetMoves'] as int,
    arrows: (json['arrows'] as List)
        .map((e) => ArrowModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

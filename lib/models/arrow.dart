/// The four directions an arrow can point / escape towards.
enum ArrowDir { up, down, left, right }

extension ArrowDirX on ArrowDir {
  /// Row/col step taken when travelling in this direction.
  ({int row, int col}) get vector => switch (this) {
    ArrowDir.up => (row: -1, col: 0),
    ArrowDir.down => (row: 1, col: 0),
    ArrowDir.left => (row: 0, col: -1),
    ArrowDir.right => (row: 0, col: 1),
  };

  static ArrowDir fromName(String name) =>
      ArrowDir.values.firstWhere((d) => d.name == name);
}

/// A single arrow on the board.
class ArrowModel {
  final String id;
  int row;
  int col;
  final ArrowDir dir;

  /// 0 = default neutral arrow; >0 selects a colored variant.
  final int color;

  ArrowModel({
    required this.id,
    required this.row,
    required this.col,
    required this.dir,
    this.color = 0,
  });

  ArrowModel copyWith({int? row, int? col}) => ArrowModel(
    id: id,
    row: row ?? this.row,
    col: col ?? this.col,
    dir: dir,
    color: color,
  );

  factory ArrowModel.fromJson(Map<String, dynamic> json) => ArrowModel(
    id: json['id'] as String,
    row: json['row'] as int,
    col: json['col'] as int,
    dir: ArrowDirX.fromName(json['dir'] as String),
    color: (json['color'] as int?) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'row': row,
    'col': col,
    'dir': dir.name,
    'color': color,
  };
}

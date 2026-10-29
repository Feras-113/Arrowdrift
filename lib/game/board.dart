/// Pure game logic for Arrowdrift. No Flutter imports so it can be unit tested
/// with plain `dart test` / `flutter test`.
library;

/// Direction an arrow head points in (and the way it slides off the board).
enum Dir {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const Dir(this.dx, this.dy);
  final int dx;
  final int dy;
}

/// One snake-like arrow. [cells] run from tail to head; each cell is
/// `y * width + x`.
class Arrow {
  const Arrow(this.id, this.dir, this.cells);

  final int id;
  final Dir dir;
  final List<int> cells;

  int get head => cells.last;
  int get length => cells.length;
}

/// A parsed level definition.
class Level {
  const Level(this.number, this.width, this.height, this.arrows);

  /// Parses the compact asset format `[w, h, [[dir, c0, ..., cHead], ...]]`.
  factory Level.fromJson(int number, List<dynamic> json) {
    final w = json[0] as int;
    final h = json[1] as int;
    final raw = json[2] as List<dynamic>;
    final arrows = <Arrow>[
      for (var i = 0; i < raw.length; i++)
        () {
          final a = (raw[i] as List<dynamic>).cast<int>();
          return Arrow(i, Dir.values[a[0]], List<int>.unmodifiable(a.sublist(1)));
        }(),
    ];
    return Level(number, w, h, arrows);
  }

  final int number;
  final int width;
  final int height;
  final List<Arrow> arrows;
}

enum TapOutcome { removed, blocked, ignored }

class TapResult {
  const TapResult(this.outcome, [this.blockerId]);

  final TapOutcome outcome;

  /// The arrow standing in the way when [outcome] is [TapOutcome.blocked].
  final int? blockerId;
}

/// Mutable state of one play-through of a [Level].
class Board {
  Board(this.level)
      : _owner = List<int>.filled(level.width * level.height, -1),
        _alive = List<bool>.filled(level.arrows.length, true),
        _remaining = level.arrows.length {
    for (final a in level.arrows) {
      for (final c in a.cells) {
        _owner[c] = a.id;
      }
    }
  }

  final Level level;
  final List<int> _owner;
  final List<bool> _alive;
  final List<int> _history = <int>[];
  int _remaining;

  int get width => level.width;
  int get height => level.height;
  List<Arrow> get arrows => level.arrows;
  int get remaining => _remaining;
  bool get solved => _remaining == 0;
  bool get canUndo => _history.isNotEmpty;

  bool isAlive(int id) => _alive[id];

  /// The live arrow occupying grid cell ([x], [y]), or null.
  Arrow? arrowAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    final id = _owner[y * width + x];
    return id == -1 ? null : level.arrows[id];
  }

  /// First live arrow on [a]'s exit ray, or null when the way is clear.
  int? blockerOf(Arrow a) {
    var x = a.head % width + a.dir.dx;
    var y = a.head ~/ width + a.dir.dy;
    while (x >= 0 && y >= 0 && x < width && y < height) {
      final o = _owner[y * width + x];
      if (o != -1 && o != a.id) return o;
      x += a.dir.dx;
      y += a.dir.dy;
    }
    return null;
  }

  bool canRemove(Arrow a) => _alive[a.id] && blockerOf(a) == null;

  /// Number of empty cells between the head and the board edge.
  int cellsToEdge(Arrow a) {
    final x = a.head % width;
    final y = a.head ~/ width;
    switch (a.dir) {
      case Dir.up:
        return y;
      case Dir.down:
        return height - 1 - y;
      case Dir.left:
        return x;
      case Dir.right:
        return width - 1 - x;
    }
  }

  TapResult tap(int id) {
    if (id < 0 || id >= _alive.length || !_alive[id]) {
      return const TapResult(TapOutcome.ignored);
    }
    final a = level.arrows[id];
    final blocker = blockerOf(a);
    if (blocker != null) return TapResult(TapOutcome.blocked, blocker);
    for (final c in a.cells) {
      _owner[c] = -1;
    }
    _alive[id] = false;
    _remaining--;
    _history.add(id);
    return const TapResult(TapOutcome.removed);
  }

  /// Puts the most recently removed arrow back. Returns its id, or null.
  int? undo() {
    if (_history.isEmpty) return null;
    final id = _history.removeLast();
    final a = level.arrows[id];
    for (final c in a.cells) {
      _owner[c] = id;
    }
    _alive[id] = true;
    _remaining++;
    return id;
  }

  /// Best arrow to point out: a removable one that unblocks the most others.
  Arrow? hint() {
    final free = <Arrow>[
      for (final a in level.arrows)
        if (_alive[a.id] && blockerOf(a) == null) a,
    ];
    if (free.isEmpty) return null;
    final score = <int, int>{for (final a in free) a.id: 0};
    for (final a in level.arrows) {
      if (!_alive[a.id]) continue;
      final b = blockerOf(a);
      if (b != null && score.containsKey(b)) score[b] = score[b]! + 1;
    }
    free.sort((p, q) {
      final c = score[q.id]!.compareTo(score[p.id]!);
      return c != 0 ? c : p.id.compareTo(q.id);
    });
    return free.first;
  }

  /// Greedy solvability check (removing a free arrow never hurts).
  static bool isSolvable(Level level) {
    final b = Board(level);
    var progress = true;
    while (!b.solved && progress) {
      progress = false;
      for (final a in level.arrows) {
        if (b.canRemove(a)) {
          b.tap(a.id);
          progress = true;
        }
      }
    }
    return b.solved;
  }
}

import 'package:flutter/material.dart';

/// Total number of bundled levels (must match tool/gen_levels.py).
const int kTotalLevels = 5100;

/// Levels stored per asset chunk file.
const int kChunkSize = 100;

enum TierId { easy, medium, hard, expert }

class Tier {
  const Tier(this.id, this.first, this.last, this.color);

  final TierId id;
  final int first;
  final int last;
  final Color color;

  int get count => last - first + 1;
}

const List<Tier> kTiers = <Tier>[
  Tier(TierId.easy, 1, 1000, Color(0xFF5BE37D)),
  Tier(TierId.medium, 1001, 2500, Color(0xFFFFC857)),
  Tier(TierId.hard, 2501, 4000, Color(0xFFFF8A5B)),
  Tier(TierId.expert, 4001, 5100, Color(0xFFFF4D6D)),
];

Tier tierOf(int level) {
  for (final t in kTiers) {
    if (level >= t.first && level <= t.last) return t;
  }
  return kTiers.last;
}

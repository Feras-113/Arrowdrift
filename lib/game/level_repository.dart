import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'board.dart';
import 'tiers.dart';

/// Loads levels lazily from `assets/levels/chunk_NNN.json` (100 per file) and
/// keeps the few most recently used chunks in memory.
class LevelRepository {
  LevelRepository._();

  static final LevelRepository instance = LevelRepository._();

  final Map<int, List<dynamic>> _chunks = <int, List<dynamic>>{};
  final List<int> _lru = <int>[];

  Future<Level> load(int number) async {
    final n = number.clamp(1, kTotalLevels);
    final chunkIndex = (n - 1) ~/ kChunkSize;
    final chunk = await _chunk(chunkIndex);
    return Level.fromJson(n, chunk[(n - 1) % kChunkSize] as List<dynamic>);
  }

  Future<List<dynamic>> _chunk(int index) async {
    final cached = _chunks[index];
    if (cached != null) {
      _lru
        ..remove(index)
        ..add(index);
      return cached;
    }
    final name = 'assets/levels/chunk_${index.toString().padLeft(3, '0')}.json';
    final text = await rootBundle.loadString(name);
    final data = jsonDecode(text) as List<dynamic>;
    _chunks[index] = data;
    _lru.add(index);
    while (_lru.length > 3) {
      _chunks.remove(_lru.removeAt(0));
    }
    return data;
  }
}

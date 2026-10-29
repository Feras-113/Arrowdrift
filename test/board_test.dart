import 'dart:convert';
import 'dart:io';

import 'package:arrowdrift/game/board.dart';
import 'package:arrowdrift/game/tiers.dart';
import 'package:flutter_test/flutter_test.dart';

Level _tiny() => Level.fromJson(1, jsonDecode('[3,3,[[1,0,1],[0,2]]]') as List<dynamic>);

void main() {
  group('Board', () {
    test('blocked arrow stays, free arrow leaves, undo restores', () {
      final b = Board(_tiny());
      expect(b.remaining, 2);

      final blocked = b.tap(0);
      expect(blocked.outcome, TapOutcome.blocked);
      expect(blocked.blockerId, 1);
      expect(b.remaining, 2);

      expect(b.tap(1).outcome, TapOutcome.removed);
      expect(b.remaining, 1);
      expect(b.tap(1).outcome, TapOutcome.ignored);

      expect(b.tap(0).outcome, TapOutcome.removed);
      expect(b.solved, isTrue);

      expect(b.undo(), 0);
      expect(b.remaining, 1);
      expect(b.undo(), 1);
      expect(b.remaining, 2);
      expect(b.undo(), isNull);
    });

    test('hint returns a removable arrow', () {
      final b = Board(_tiny());
      final h = b.hint();
      expect(h, isNotNull);
      expect(b.canRemove(h!), isTrue);
      expect(h.id, 1);
    });

    test('arrowAt maps cells to arrows', () {
      final b = Board(_tiny());
      expect(b.arrowAt(0, 0)?.id, 0);
      expect(b.arrowAt(1, 0)?.id, 0);
      expect(b.arrowAt(2, 0)?.id, 1);
      expect(b.arrowAt(0, 2), isNull);
      expect(b.arrowAt(-1, 0), isNull);
    });

    test('cellsToEdge counts free cells to the border', () {
      final b = Board(_tiny());
      expect(b.cellsToEdge(b.arrows[0]), 1); // head x=1 heading right in w=3
      expect(b.cellsToEdge(b.arrows[1]), 0); // head y=0 heading up
    });
  });

  group('Bundled levels', () {
    test('all $kTotalLevels levels are structurally valid and solvable', () {
      var count = 0;
      for (var c = 0; c * kChunkSize < kTotalLevels; c++) {
        final file = File('assets/levels/chunk_${c.toString().padLeft(3, '0')}.json');
        expect(file.existsSync(), isTrue, reason: '${file.path} missing');
        final chunk = jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (var i = 0; i < chunk.length; i++) {
          final n = c * kChunkSize + i + 1;
          final level = Level.fromJson(n, chunk[i] as List<dynamic>);
          final seen = <int>{};
          for (final a in level.arrows) {
            expect(a.cells, isNotEmpty);
            for (final cell in a.cells) {
              expect(cell, inInclusiveRange(0, level.width * level.height - 1));
              expect(seen.add(cell), isTrue, reason: 'level $n overlaps at $cell');
            }
            for (var k = 1; k < a.cells.length; k++) {
              final p = a.cells[k - 1];
              final q = a.cells[k];
              final d = (p % level.width - q % level.width).abs() +
                  (p ~/ level.width - q ~/ level.width).abs();
              expect(d, 1, reason: 'level $n has non-adjacent cells');
            }
            if (a.cells.length >= 2) {
              final p = a.cells[a.cells.length - 2];
              final q = a.cells.last;
              expect(q % level.width - p % level.width, a.dir.dx, reason: 'level $n head dir');
              expect(q ~/ level.width - p ~/ level.width, a.dir.dy, reason: 'level $n head dir');
            }
          }
          expect(Board.isSolvable(level), isTrue, reason: 'level $n is unsolvable');
          count++;
        }
      }
      expect(count, kTotalLevels);
    });
  });
}

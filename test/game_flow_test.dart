import 'package:arrowdrift/game/board.dart';
import 'package:arrowdrift/game/level_repository.dart';
import 'package:arrowdrift/services/progress.dart';
import 'package:arrowdrift/l10n/strings.dart';
import 'package:arrowdrift/theme/context_x.dart';
import 'package:arrowdrift/ui/board_painter.dart';
import 'package:arrowdrift/ui/screens/game_screen.dart';
import 'package:arrowdrift/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Progress progress, Widget home) {
  return ProgressScope(
    progress: progress,
    child: Builder(
      builder: (context) => MaterialApp(
        theme: context.pal.toTheme(),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
}

Finder get _boardFinder => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is BoardPainter,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('tap free arrow removes it; tap blocked arrow costs a heart',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = await Progress.load();
    await tester.runAsync(() => LevelRepository.instance.load(5));
    await tester.pumpWidget(_app(progress, const GameScreen(levelNumber: 5)));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_boardFinder, findsOneWidget);
    final painter = tester.widget<CustomPaint>(_boardFinder).painter! as BoardPainter;
    final board = painter.board;
    final rect = tester.getRect(_boardFinder);
    final geo = BoardGeometry(rect.size, board.width, board.height);

    Offset where(Arrow a) => rect.topLeft + geo.center(a.head);

    // 1) blocked arrow -> heart lost, arrow stays.
    final blocked = board.arrows.where((a) => !board.canRemove(a)).first;
    final before = board.remaining;
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    await tester.tapAt(where(blocked));
    await tester.pump(const Duration(milliseconds: 100));
    expect(board.remaining, before);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 1));

    // 2) free arrow -> removed.
    final free = board.arrows.firstWhere(board.canRemove);
    await tester.tapAt(where(free));
    await tester.pump(const Duration(milliseconds: 50));
    expect(board.remaining, before - 1);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('solving a whole level shows the win dialog and unlocks the next',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = await Progress.load();
    await tester.runAsync(() => LevelRepository.instance.load(2));
    await tester.pumpWidget(_app(progress, const GameScreen(levelNumber: 2)));
    await tester.pump(const Duration(milliseconds: 100));

    final painter = tester.widget<CustomPaint>(_boardFinder).painter! as BoardPainter;
    final board = painter.board;
    final rect = tester.getRect(_boardFinder);
    final geo = BoardGeometry(rect.size, board.width, board.height);

    while (!board.solved) {
      final a = board.arrows.firstWhere(board.canRemove);
      await tester.tapAt(rect.topLeft + geo.center(a.head));
      await tester.pump(const Duration(milliseconds: 450));
    }
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Level clear!'), findsOneWidget);
    expect(progress.unlocked, 3);
    expect(progress.starsFor(2), 3);
    expect(progress.coins, greaterThan(0));
  });

  testWidgets('home screen renders and shows the current level', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = await Progress.load();
    await tester.pumpWidget(_app(progress, const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ARROWDRIFT'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.textContaining('Level 1'), findsOneWidget);
  });
}

// ignore_for_file: invalid_use_of_visible_for_testing_member, unawaited_futures
// Renders key screens to PNGs in build/shots/ for visual review:
//   flutter test tool/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrowdrift/game/level_repository.dart';
import 'package:arrowdrift/l10n/strings.dart';
import 'package:arrowdrift/services/progress.dart';
import 'package:arrowdrift/theme/context_x.dart';
import 'package:arrowdrift/ui/dialogs.dart';
import 'package:arrowdrift/ui/screens/game_screen.dart';
import 'package:arrowdrift/ui/screens/home_screen.dart';
import 'package:arrowdrift/ui/screens/level_select_screen.dart';
import 'package:arrowdrift/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey _key = GlobalKey();

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$dir/$f');
      if (file.existsSync()) {
        loader.addFont(Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())));
      }
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

Widget _app(Progress progress, Widget home) => RepaintBoundary(
      key: _key,
      child: ProgressScope(
        progress: progress,
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
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
      ),
    );

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_key));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('build/shots/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

Future<Progress> _progress({int unlocked = 1800, String theme = 'neon'}) async {
  final stars = StringBuffer();
  for (var i = 1; i <= 5100; i++) {
    stars.write(i < unlocked ? '${1 + i % 3}' : '0');
  }
  SharedPreferences.setMockInitialValues(<String, Object>{
    'unlocked': unlocked,
    'coins': 340,
    'stars': stars.toString(),
    'theme': theme,
    'themes': <String>['neon', 'paper'],
  });
  return Progress.load();
}

void main() {
  setUpAll(_loadFonts);

  Future<void> game(WidgetTester tester, int level, String name,
      {String theme = 'neon', Future<void> Function()? extra}) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = await _progress(unlocked: level, theme: theme);
    await tester.runAsync(() => LevelRepository.instance.load(level));
    await tester.pumpWidget(_app(p, GameScreen(levelNumber: level)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    if (extra != null) await extra();
    await _shot(tester, name);
  }

  testWidgets('shot home', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = await _progress();
    await tester.pumpWidget(_app(p, const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(tester, '01_home');
  });

  testWidgets('shot levels', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = await _progress(unlocked: 1003);
    await tester.pumpWidget(_app(p, const LevelSelectScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await _shot(tester, '02_levels');
  });

  testWidgets('shot game easy', (tester) => game(tester, 1, '03_game_L1'));
  testWidgets('shot game medium', (tester) => game(tester, 1800, '04_game_L1800'));
  testWidgets('shot game hard', (tester) => game(tester, 3200, '05_game_L3200'));
  testWidgets('shot game expert', (tester) => game(tester, 5000, '06_game_L5000'));

  testWidgets('shot game hint', (tester) async {
    await game(tester, 2600, '07_game_hint_L2600', extra: () async {
      await tester.tap(find.byIcon(Icons.lightbulb_rounded));
      await tester.pump(const Duration(milliseconds: 400));
    });
  });

  testWidgets('shot game paper', (tester) => game(tester, 1500, '08_game_paper', theme: 'paper'));

  testWidgets('shot settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = await _progress();
    await tester.pumpWidget(_app(p, const SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await _shot(tester, '09_settings');
  });

  testWidgets('shot win dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = await _progress();
    await tester.runAsync(() => LevelRepository.instance.load(1800));
    await tester.pumpWidget(_app(p, const GameScreen(levelNumber: 1800)));
    await tester.pump(const Duration(milliseconds: 100));
    final ctx = tester.element(find.byType(GameScreen));
    showWinDialog(ctx, stars: 3, coins: 30, isLast: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await _shot(tester, '10_win');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'services/progress.dart';
import 'theme/context_x.dart';
import 'ui/screens/splash_screen.dart';

class ArrowdriftApp extends StatelessWidget {
  const ArrowdriftApp({super.key, required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      progress: progress,
      child: Builder(
        builder: (context) {
          final pal = context.pal;
          return MaterialApp(
            title: 'Arrowdrift',
            debugShowCheckedModeBanner: false,
            theme: pal.toTheme(),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: (pal.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                  .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
              child: child!,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

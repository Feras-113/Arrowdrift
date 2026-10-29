import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/level_repository.dart';
import '../../theme/context_x.dart';
import '../route.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    // Warm up the first level chunk while the logo animates.
    await Future.wait<void>([
      LevelRepository.instance.load(1).then((_) {}),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(fadeRoute<void>(const HomeScreen())),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoMark(size: 150),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [pal.accent, pal.accent2],
                    ).createShader(rect),
                    child: const Text(
                      'ARROWDRIFT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

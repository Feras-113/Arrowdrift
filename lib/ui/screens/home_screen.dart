import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/tiers.dart';
import '../../theme/context_x.dart';
import '../route.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = context.s;
    final progress = context.progress;
    final tier = tierOf(progress.unlocked);
    final tierName = switch (tier.id) {
      TierId.easy => s.easy,
      TierId.medium => s.medium,
      TierId.hard => s.hard,
      TierId.expert => s.expert,
    };

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    CoinChip(coins: progress.coins),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: pal.gold, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '${progress.totalStars}',
                          style: TextStyle(
                            color: pal.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: Icons.settings_rounded,
                      tooltip: s.settings,
                      size: 48,
                      onPressed: () => Navigator.of(context)
                          .push(fadeRoute<void>(const SettingsScreen())),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, math.sin(_float.value * 2 * math.pi) * 7),
                  child: child,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: pal.accent.withValues(alpha: 0.3),
                        blurRadius: 50,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const LogoMark(size: 156),
                ),
              ),
              const SizedBox(height: 26),
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [pal.accent, pal.accent2],
                ).createShader(rect),
                child: const Text(
                  'ARROWDRIFT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${s.level} ${progress.unlocked} • $tierName',
                style: TextStyle(
                  color: pal.textDim,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GradientButton(
                label: s.play,
                icon: Icons.play_arrow_rounded,
                height: 64,
                minWidth: 240,
                onPressed: () => Navigator.of(context).push(
                  fadeRoute<void>(GameScreen(levelNumber: progress.unlocked)),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: s.levels,
                icon: Icons.grid_view_rounded,
                secondary: true,
                minWidth: 240,
                onPressed: () => Navigator.of(context)
                    .push(fadeRoute<void>(const LevelSelectScreen())),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

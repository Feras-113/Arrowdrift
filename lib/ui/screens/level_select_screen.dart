import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/tiers.dart';
import '../../services/fx.dart';
import '../../theme/context_x.dart';
import '../route.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const int _cols = 5;
  static const double _gap = 10;
  static const double _pad = 16;
  static const double _headerHeight = 76;
  static const double _aspect = 0.9;

  ScrollController? _controller;

  double _tileExtent(double width) {
    final tileW = (width - _pad * 2 - _gap * (_cols - 1)) / _cols;
    return tileW / _aspect + _gap;
  }

  double _offsetFor(int level, double width) {
    final row = _tileExtent(width);
    var offset = 0.0;
    for (final t in kTiers) {
      if (level >= t.first && level <= t.last) {
        offset += _headerHeight + ((level - t.first) ~/ _cols) * row;
        break;
      }
      offset += _headerHeight + (t.count / _cols).ceil() * row;
    }
    return math.max(0, offset - 140);
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = context.s;
    final progress = context.progress;
    final width = MediaQuery.sizeOf(context).width;
    _controller ??= ScrollController(
      initialScrollOffset: _offsetFor(progress.unlocked, width),
    );

    String tierName(Tier t) => switch (t.id) {
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
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: s.home,
                      size: 44,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        s.levels,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: pal.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    CoinChip(coins: progress.coins),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _controller,
                  slivers: [
                    for (final tier in kTiers) ...[
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _headerHeight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(_pad, 28, _pad, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: tier.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  tierName(tier),
                                  style: TextStyle(
                                    color: pal.text,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${tier.first}–${tier.last}',
                                  style: TextStyle(color: pal.textDim, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: _pad),
                        sliver: SliverGrid.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _cols,
                            mainAxisSpacing: _gap,
                            crossAxisSpacing: _gap,
                            childAspectRatio: _aspect,
                          ),
                          itemCount: tier.count,
                          itemBuilder: (context, i) =>
                              _LevelTile(number: tier.first + i, tier: tier),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.number, required this.tier});

  final int number;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final progress = context.progress;
    final locked = number > progress.unlocked;
    final current = number == progress.unlocked;
    final stars = progress.starsFor(number);

    final Color fill;
    final Color border;
    if (locked) {
      fill = pal.surface.withValues(alpha: 0.35);
      border = pal.text.withValues(alpha: 0.05);
    } else if (current) {
      fill = tier.color.withValues(alpha: 0.9);
      border = Colors.white.withValues(alpha: 0.6);
    } else {
      fill = pal.surface.withValues(alpha: 0.95);
      border = tier.color.withValues(alpha: 0.55);
    }
    final fg = current ? (pal.isDark ? pal.bgTop : Colors.white) : pal.text;

    return Semantics(
      button: true,
      enabled: !locked,
      label: 'Level $number',
      child: GestureDetector(
        onTap: () {
          if (locked) {
            Fx.instance.error();
            return;
          }
          Fx.instance.click();
          Navigator.of(context).push(fadeRoute<void>(GameScreen(levelNumber: number)));
        },
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: current ? 2 : 1.2),
            boxShadow: current
                ? [BoxShadow(color: tier.color.withValues(alpha: 0.45), blurRadius: 14)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                Icon(Icons.lock_rounded, color: pal.textDim.withValues(alpha: 0.6), size: 20)
              else
                Text(
                  '$number',
                  style: TextStyle(
                    color: fg,
                    fontSize: number >= 1000 ? 15 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 4),
              if (!locked) StarsRow(stars: stars, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

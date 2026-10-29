import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../services/ad_service.dart';
import '../../services/fx.dart';
import '../../theme/context_x.dart';
import '../../theme/palette.dart';

/// Gradient backdrop with a few faint decorative arrows.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.bgTop, pal.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: CustomPaint(painter: _DecorPainter(pal))),
          child,
        ],
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  const _DecorPainter(this.pal);

  final AppPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 16; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 40 + rnd.nextDouble() * 90;
      final turn = rnd.nextBool() ? 1.0 : -1.0;
      final paint = Paint()
        ..color = pal.arrows[i % pal.arrows.length].withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(x, y)
        ..lineTo(x, y - len)
        ..lineTo(x + turn * len * 0.6, y - len);
      canvas.drawPath(path, paint);
      final tip = Offset(x + turn * len * 0.6, y - len);
      final head = Path()
        ..moveTo(tip.dx + turn * 18, tip.dy)
        ..lineTo(tip.dx, tip.dy - 14)
        ..lineTo(tip.dx, tip.dy + 14)
        ..close();
      canvas.drawPath(head, Paint()..color = paint.color);
    }
  }

  @override
  bool shouldRepaint(_DecorPainter oldDelegate) => oldDelegate.pal.id != pal.id;
}

/// Big call-to-action button with a soft glow and press animation.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 58,
    this.minWidth = 160,
    this.secondary = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double minWidth;
  final bool secondary;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final enabled = widget.onPressed != null;
    final fg = widget.secondary
        ? pal.text
        : (pal.isDark ? pal.bgTop : Colors.white);
    final decoration = widget.secondary
        ? BoxDecoration(
            color: pal.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pal.text.withValues(alpha: 0.12)),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              colors: [pal.accent, Color.lerp(pal.accent, pal.accent2, 0.55)!],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: pal.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled
            ? () {
                Fx.instance.click();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              height: widget.height,
              constraints: BoxConstraints(minWidth: widget.minWidth),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: fg,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
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

/// Circular glass icon button (min 48dp touch target) with optional count badge.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badge,
    this.badgeIcon,
    this.size = 56,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final int? badge;
  final IconData? badgeIcon;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final active = enabled && onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: active,
        label: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: active
              ? () {
                  Fx.instance.click();
                  onPressed!();
                }
              : null,
          child: SizedBox(
            width: size + 8,
            height: size + 8,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: active ? 1 : 0.4,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pal.surface.withValues(alpha: 0.9),
                      border: Border.all(color: pal.text.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: pal.text, size: size * 0.46),
                  ),
                ),
                if (badge != null || badgeIcon != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: badgeIcon != null ? pal.accent2 : pal.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: badgeIcon != null
                          ? Icon(badgeIcon, size: 14, color: Colors.white)
                          : Text(
                              '$badge',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: pal.isDark ? pal.bgTop : Colors.white,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: pal.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pal.text.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: pal.gold, size: 24),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: pal.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class HeartsRow extends StatelessWidget {
  const HeartsRow({super.key, required this.hearts, this.max = 3});

  final int hearts;
  final int max;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          AnimatedScale(
            scale: i < hearts ? 1 : 0.8,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              i < hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: i < hearts ? pal.danger : pal.textDim,
              size: 26,
            ),
          ),
      ],
    );
  }
}

class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.stars, this.size = 16, this.total = 3});

  final int stars;
  final double size;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i < stars ? pal.gold : pal.textDim.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

/// Adaptive AdMob banner. Collapses to nothing until an ad has loaded.
class AdaptiveBanner extends StatefulWidget {
  const AdaptiveBanner({super.key});

  @override
  State<AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<AdaptiveBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.started.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (_ad != null || _loading || !mounted) return;
    if (!AdService.instance.started.value) return;
    _loading = true;
    final view = View.of(context);
    final width = (view.physicalSize.width / view.devicePixelRatio).truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    _loading = false;
    if (!mounted || size == null) return;
    final ad = BannerAd(
      adUnitId: AdConfig.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    AdService.instance.started.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

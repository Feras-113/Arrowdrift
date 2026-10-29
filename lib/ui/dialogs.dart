import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/fx.dart';
import '../services/progress.dart';
import '../theme/context_x.dart';
import 'widgets/common.dart';

enum Helper { hint, undo, skip }

enum WinAction { next, replay, home }

enum FailAction { revive, retry, home }

enum _GetMoreChoice { ad, coins }

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'dialog',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => SafeArea(child: Center(child: builder(ctx))),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1).animate(curved), child: child),
      );
    },
  );
}

/// Shared card chrome for all dialogs.
class DialogCard extends StatelessWidget {
  const DialogCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: pal.text.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.pal.text,
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.pal.textDim, fontSize: 15, height: 1.35),
      );
}

// ---------------------------------------------------------------- win ------

Future<WinAction?> showWinDialog(
  BuildContext context, {
  required int stars,
  required int coins,
  required bool isLast,
}) {
  return showAppDialog<WinAction>(
    context,
    builder: (ctx) {
      final s = ctx.s;
      final pal = ctx.pal;
      return DialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Title(s.levelClear),
            const SizedBox(height: 14),
            _PoppingStars(stars: stars),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on_rounded, color: pal.gold, size: 26),
                const SizedBox(width: 8),
                Text(
                  '+$coins',
                  style: TextStyle(
                    color: pal.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (isLast)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Body(s.allDone),
              )
            else
              GradientButton(
                label: s.next,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(ctx).pop(WinAction.next),
              ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundIconButton(
                  icon: Icons.replay_rounded,
                  tooltip: s.retry,
                  onPressed: () => Navigator.of(ctx).pop(WinAction.replay),
                ),
                const SizedBox(width: 12),
                RoundIconButton(
                  icon: Icons.home_rounded,
                  tooltip: s.home,
                  onPressed: () => Navigator.of(ctx).pop(WinAction.home),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _PoppingStars extends StatelessWidget {
  const _PoppingStars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: i < stars ? 1 : 0.0),
            duration: Duration(milliseconds: 350 + i * 250),
            curve: Curves.elasticOut,
            builder: (context, v, _) => Transform.scale(
              scale: 0.6 + 0.4 * v,
              child: Icon(
                Icons.star_rounded,
                size: i == 1 ? 78 : 62,
                color: Color.lerp(pal.textDim.withValues(alpha: 0.35), pal.gold, v),
              ),
            ),
          ),
      ],
    );
  }
}

// --------------------------------------------------------------- fail ------

Future<FailAction?> showFailDialog(BuildContext context) {
  return showAppDialog<FailAction>(
    context,
    builder: (ctx) {
      final s = ctx.s;
      final pal = ctx.pal;
      return DialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.heart_broken_rounded, color: pal.danger, size: 64),
            const SizedBox(height: 10),
            _Title(s.outOfHearts),
            const SizedBox(height: 8),
            _Body(s.outOfHeartsBody),
            const SizedBox(height: 22),
            ValueListenableBuilder<bool>(
              valueListenable: AdService.instance.rewardedReady,
              builder: (context, ready, _) => ready
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GradientButton(
                        label: s.revive,
                        icon: Icons.ondemand_video_rounded,
                        onPressed: () => Navigator.of(ctx).pop(FailAction.revive),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            GradientButton(
              label: s.retry,
              icon: Icons.replay_rounded,
              secondary: true,
              onPressed: () => Navigator.of(ctx).pop(FailAction.retry),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(FailAction.home),
              child: Text(s.home, style: TextStyle(color: pal.textDim, fontSize: 16)),
            ),
          ],
        ),
      );
    },
  );
}

// ------------------------------------------------------------ confirm ------

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showAppDialog<bool>(
    context,
    dismissible: true,
    builder: (ctx) {
      final pal = ctx.pal;
      return DialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Title(title),
            const SizedBox(height: 10),
            _Body(body),
            const SizedBox(height: 22),
            GradientButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: destructive ? pal.textDim : pal.textDim,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

// ----------------------------------------------------------- get more ------

int helperCost(Helper h) => switch (h) {
      Helper.hint => Progress.hintCost,
      Helper.undo => Progress.undoCost,
      Helper.skip => Progress.skipCost,
    };

void _grant(Progress p, Helper h) {
  switch (h) {
    case Helper.hint:
      p.addHints(1);
    case Helper.undo:
      p.addUndos(1);
    case Helper.skip:
      p.addSkips(1);
  }
}

void showSnack(BuildContext context, String text) {
  final pal = context.pal;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(color: pal.text, fontWeight: FontWeight.w600)),
        backgroundColor: pal.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Lets the player obtain one more [helper] (free via rewarded ad, or coins).
/// Returns true when the player ended up with one.
Future<bool> offerHelper(BuildContext context, Helper helper) async {
  final progress = ProgressScope.of(context);
  final cost = helperCost(helper);
  final choice = await showAppDialog<_GetMoreChoice>(
    context,
    dismissible: true,
    builder: (ctx) {
      final s = ctx.s;
      final pal = ctx.pal;
      final icon = switch (helper) {
        Helper.hint => Icons.lightbulb_rounded,
        Helper.undo => Icons.undo_rounded,
        Helper.skip => Icons.skip_next_rounded,
      };
      final name = switch (helper) {
        Helper.hint => s.hint,
        Helper.undo => s.undo,
        Helper.skip => s.skip,
      };
      return DialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: pal.accent, size: 52),
            const SizedBox(height: 8),
            _Title('${s.getMore}: $name'),
            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: AdService.instance.rewardedReady,
              builder: (context, ready, _) => ready
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GradientButton(
                        label: s.freeWithAd,
                        icon: Icons.ondemand_video_rounded,
                        onPressed: () => Navigator.of(ctx).pop(_GetMoreChoice.ad),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            GradientButton(
              label: '${s.buyWithCoins}  ($cost)',
              icon: Icons.monetization_on_rounded,
              secondary: true,
              onPressed: () => Navigator.of(ctx).pop(_GetMoreChoice.coins),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.cancel, style: TextStyle(color: pal.textDim, fontSize: 16)),
            ),
          ],
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return false;
  final s = context.s;
  switch (choice) {
    case _GetMoreChoice.ad:
      final earned = await AdService.instance.showRewarded();
      if (!context.mounted) return false;
      if (earned) {
        _grant(progress, helper);
        return true;
      }
      showSnack(context, s.adNotReady);
      return false;
    case _GetMoreChoice.coins:
      if (progress.spend(cost)) {
        Fx.instance.pop();
        _grant(progress, helper);
        return true;
      }
      Fx.instance.error();
      showSnack(context, s.notEnoughCoins);
      return false;
  }
}

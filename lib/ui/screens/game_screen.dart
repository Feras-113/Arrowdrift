import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/board.dart';
import '../../game/level_repository.dart';
import '../../game/tiers.dart';
import '../../services/ad_service.dart';
import '../../services/fx.dart';
import '../../services/progress.dart';
import '../../theme/context_x.dart';
import '../board_painter.dart';
import '../dialogs.dart';
import '../route.dart';
import '../widgets/common.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelNumber});

  final int levelNumber;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxHearts = 3;

  late final AnimationController _clock;
  final BoardAnimations _anim = BoardAnimations();
  Board? _board;
  BoardGeometry? _geo;
  int _hearts = _maxHearts;
  int _mistakes = 0;
  bool _ended = false;
  bool _dialogOpen = false;

  Progress get _progress =>
      context.getInheritedWidgetOfExactType<ProgressScope>()!.notifier!;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_onTick);
    _load();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final level = await LevelRepository.instance.load(widget.levelNumber);
    if (!mounted) return;
    _startBoard(Board(level));
  }

  void _startBoard(Board board) {
    setState(() {
      _anim.clear();
      _board = board;
      _hearts = _maxHearts;
      _mistakes = 0;
      _ended = false;
    });
  }

  void _pump() {
    if (!_clock.isAnimating) _clock.repeat();
  }

  void _onTick() {
    _anim.prune();
    final board = _board;
    if (board != null && board.solved && _anim.exiting.isEmpty && !_ended) {
      _ended = true;
      _clock.stop();
      _handleWin();
      return;
    }
    if (!_anim.busy) _clock.stop();
  }

  // ---------------------------------------------------------------- input --

  void _onTapDown(TapDownDetails d) {
    final board = _board;
    final geo = _geo;
    if (board == null || geo == null || _ended) return;
    final cell = geo.cellAt(d.localPosition);
    if (cell == null) return;
    final arrow = board.arrowAt(cell.x, cell.y);
    if (arrow == null) return;

    final result = board.tap(arrow.id);
    switch (result.outcome) {
      case TapOutcome.removed:
        Fx.instance.pop();
        if (_anim.hintId == arrow.id) _anim.clearHint();
        _anim.startExit(arrow.id);
        _pump();
        setState(() {});
      case TapOutcome.blocked:
        Fx.instance.error();
        _anim.startFlash(arrow.id, result.blockerId);
        _pump();
        setState(() {
          _hearts--;
          _mistakes++;
        });
        if (_hearts <= 0) {
          _ended = true;
          Future<void>.delayed(const Duration(milliseconds: 550), _handleFail);
        }
      case TapOutcome.ignored:
        break;
    }
  }

  // -------------------------------------------------------------- helpers --

  Future<void> _useHint() async {
    final board = _board;
    if (board == null || _ended || _dialogOpen) return;
    if (_progress.hints <= 0) {
      _dialogOpen = true;
      final got = await offerHelper(context, Helper.hint);
      _dialogOpen = false;
      if (!got || !mounted) return;
    }
    final arrow = board.hint();
    if (arrow == null) {
      showSnack(context, context.s.noMoves);
      return;
    }
    if (!_progress.useHint()) return;
    _anim.showHint(arrow.id);
    _pump();
    setState(() {});
  }

  Future<void> _useUndo() async {
    final board = _board;
    if (board == null || _ended || _dialogOpen || !board.canUndo) return;
    if (_progress.undos <= 0) {
      _dialogOpen = true;
      final got = await offerHelper(context, Helper.undo);
      _dialogOpen = false;
      if (!got || !mounted) return;
    }
    if (!board.canUndo || !_progress.useUndo()) return;
    final id = board.undo();
    if (id != null) _anim.cancel(id);
    Fx.instance.click();
    setState(() {});
  }

  Future<void> _useSkip() async {
    final board = _board;
    if (board == null || _ended || _dialogOpen) return;
    final s = context.s;
    _dialogOpen = true;
    final sure = await showConfirmDialog(
      context,
      title: s.skipTitle,
      body: s.skipBody,
      confirmLabel: s.skip,
      cancelLabel: s.cancel,
    );
    if (!mounted) return;
    if (!sure) {
      _dialogOpen = false;
      return;
    }
    if (_progress.skips <= 0) {
      final got = await offerHelper(context, Helper.skip);
      if (!got || !mounted) {
        _dialogOpen = false;
        return;
      }
    }
    _dialogOpen = false;
    if (!_progress.useSkip()) return;
    _ended = true;
    _progress.skipLevel(widget.levelNumber);
    _goToNext();
  }

  // ------------------------------------------------------------ outcomes --

  void _goToNext() {
    if (!mounted) return;
    final next = widget.levelNumber + 1;
    if (next > kTotalLevels) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        fadeRoute<void>(GameScreen(levelNumber: next)),
      );
    }
  }

  Future<void> _handleWin() async {
    final progress = _progress;
    final stars = _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1);
    final coins = progress.completeLevel(widget.levelNumber, stars);
    Fx.instance.win();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final action = await showWinDialog(
      context,
      stars: stars,
      coins: coins,
      isLast: widget.levelNumber >= kTotalLevels,
    );
    if (!mounted) return;
    switch (action) {
      case WinAction.next:
        await AdService.instance.maybeShowInterstitial(progress, widget.levelNumber);
        _goToNext();
      case WinAction.replay:
        _startBoard(Board(_board!.level));
      case WinAction.home:
      case null:
        Navigator.of(context).pop();
    }
  }

  Future<void> _handleFail() async {
    if (!mounted) return;
    final action = await showFailDialog(context);
    if (!mounted) return;
    switch (action) {
      case FailAction.revive:
        final earned = await AdService.instance.showRewarded();
        if (!mounted) return;
        if (earned) {
          setState(() {
            _hearts = 2;
            _ended = false;
          });
        } else {
          showSnack(context, context.s.adNotReady);
          unawaited(_handleFail());
        }
      case FailAction.retry:
        _startBoard(Board(_board!.level));
      case FailAction.home:
      case null:
        Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = context.s;
    final board = _board;
    final progress = context.progress;
    final tier = tierOf(widget.levelNumber);
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
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: s.home,
                      size: 44,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${s.level} ${widget.levelNumber}',
                            style: TextStyle(
                              color: pal.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: tier.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                board == null
                                    ? tierName
                                    : '$tierName • ${board.remaining}',
                                style: TextStyle(
                                  color: pal.textDim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    HeartsRow(hearts: _hearts, max: _maxHearts),
                  ],
                ),
              ),
              if (widget.levelNumber <= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: Text(
                    s.tapHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: pal.textDim, fontSize: 14),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: board == null
                      ? Center(child: CircularProgressIndicator(color: pal.accent))
                      : LayoutBuilder(
                          builder: (context, cons) {
                            final size = Size(cons.maxWidth, cons.maxHeight);
                            _geo = BoardGeometry(size, board.width, board.height);
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: _onTapDown,
                              child: CustomPaint(
                                size: size,
                                painter: BoardPainter(
                                  board: board,
                                  anim: _anim,
                                  pal: pal,
                                  repaint: _clock,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _HelperButton(
                      icon: Icons.lightbulb_rounded,
                      label: s.hint,
                      count: progress.hints,
                      onPressed: _useHint,
                    ),
                    _HelperButton(
                      icon: Icons.undo_rounded,
                      label: s.undo,
                      count: progress.undos,
                      enabled: board?.canUndo ?? false,
                      onPressed: _useUndo,
                    ),
                    _HelperButton(
                      icon: Icons.skip_next_rounded,
                      label: s.skip,
                      count: progress.skips,
                      onPressed: _useSkip,
                    ),
                  ],
                ),
              ),
              const AdaptiveBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelperButton extends StatelessWidget {
  const _HelperButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          icon: icon,
          tooltip: label,
          enabled: enabled,
          badge: count > 0 ? count : null,
          badgeIcon: count > 0 ? null : Icons.add_rounded,
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            color: pal.textDim,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

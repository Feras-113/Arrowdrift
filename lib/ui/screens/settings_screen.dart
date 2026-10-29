import 'package:flutter/material.dart';

import '../../services/ad_service.dart';
import '../../services/fx.dart';
import '../../theme/context_x.dart';
import '../../theme/palette.dart';
import '../dialogs.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _privacyOptions = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.privacyOptionsRequired().then((v) {
      if (mounted) setState(() => _privacyOptions = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = context.s;
    final progress = context.progress;

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
                        s.settings,
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _Card(
                      child: Column(
                        children: [
                          _SwitchRow(
                            icon: Icons.volume_up_rounded,
                            label: s.sound,
                            value: progress.sound,
                            onChanged: progress.setSound,
                          ),
                          Divider(height: 1, color: pal.text.withValues(alpha: 0.08)),
                          _SwitchRow(
                            icon: Icons.vibration_rounded,
                            label: s.haptics,
                            value: progress.haptics,
                            onChanged: progress.setHaptics,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 10),
                      child: Text(
                        s.themes,
                        style: TextStyle(
                          color: pal.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        for (final p in kPalettes) _ThemeCard(palette: p),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Card(
                      child: Column(
                        children: [
                          if (_privacyOptions) ...[
                            _ActionRow(
                              icon: Icons.privacy_tip_rounded,
                              label: s.adPrivacy,
                              onTap: AdService.instance.showPrivacyOptions,
                            ),
                            Divider(height: 1, color: pal.text.withValues(alpha: 0.08)),
                          ],
                          _ActionRow(
                            icon: Icons.delete_outline_rounded,
                            label: s.resetProgress,
                            color: pal.danger,
                            onTap: () async {
                              final ok = await showConfirmDialog(
                                context,
                                title: s.resetProgress,
                                body: s.resetBody,
                                confirmLabel: s.reset,
                                cancelLabel: s.cancel,
                                destructive: true,
                              );
                              if (ok) await progress.reset();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        s.about,
                        style: TextStyle(color: pal.textDim, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: pal.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pal.text.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return SwitchListTile(
      value: value,
      onChanged: (v) {
        onChanged(v);
        Fx.instance.click();
      },
      activeThumbColor: pal.accent,
      secondary: Icon(icon, color: pal.accent),
      title: Text(
        label,
        style: TextStyle(color: pal.text, fontWeight: FontWeight.w700, fontSize: 17),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pal.text;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 17),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = context.s;
    final progress = context.progress;
    final owned = progress.ownedThemes.contains(palette.id);
    final selected = progress.themeId == palette.id;

    return Semantics(
      button: true,
      selected: selected,
      label: palette.name,
      child: GestureDetector(
        onTap: () {
          if (owned) {
            progress.selectTheme(palette);
            Fx.instance.click();
          } else if (progress.buyTheme(palette)) {
            Fx.instance.pop();
          } else {
            Fx.instance.error();
            showSnack(context, s.notEnoughCoins);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.bgTop, palette.bgBottom],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? pal.accent : pal.text.withValues(alpha: 0.12),
              width: selected ? 3 : 1.2,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final c in palette.arrows.take(4))
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsetsDirectional.only(end: 5),
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                palette.name,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              if (selected)
                Text(
                  s.selected,
                  style: TextStyle(color: palette.accent, fontWeight: FontWeight.w800, fontSize: 13),
                )
              else if (owned)
                Text(s.owned, style: TextStyle(color: palette.textDim, fontSize: 13))
              else
                Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, color: palette.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${palette.price}',
                      style: TextStyle(
                        color: palette.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

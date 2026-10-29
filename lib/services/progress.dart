import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/tiers.dart';
import '../theme/palette.dart';

/// Everything the player owns or has done, persisted locally.
class Progress extends ChangeNotifier {
  Progress._(this._prefs);

  static const int hintCost = 30;
  static const int undoCost = 20;
  static const int skipCost = 100;

  final SharedPreferences _prefs;

  int unlocked = 1;
  int coins = 0;
  int hints = 3;
  int undos = 3;
  int skips = 1;
  bool sound = true;
  bool haptics = true;
  String themeId = kNeon.id;
  Set<String> ownedThemes = <String>{kNeon.id};
  String _stars = '0' * kTotalLevels;

  /// Levels completed since the last interstitial (not persisted).
  int levelsSinceAd = 0;

  AppPalette get palette => paletteById(themeId);

  static Future<Progress> load() async {
    final p = Progress._(await SharedPreferences.getInstance());
    p._read();
    return p;
  }

  void _read() {
    unlocked = (_prefs.getInt('unlocked') ?? 1).clamp(1, kTotalLevels);
    coins = _prefs.getInt('coins') ?? 0;
    hints = _prefs.getInt('hints') ?? 3;
    undos = _prefs.getInt('undos') ?? 3;
    skips = _prefs.getInt('skips') ?? 1;
    sound = _prefs.getBool('sound') ?? true;
    haptics = _prefs.getBool('haptics') ?? true;
    themeId = _prefs.getString('theme') ?? kNeon.id;
    ownedThemes = (_prefs.getStringList('themes') ?? <String>[kNeon.id]).toSet();
    final s = _prefs.getString('stars');
    if (s != null && s.length == kTotalLevels) _stars = s;
    if (!ownedThemes.contains(themeId)) themeId = kNeon.id;
  }

  int starsFor(int level) {
    if (level < 1 || level > kTotalLevels) return 0;
    return _stars.codeUnitAt(level - 1) - 0x30;
  }

  int get totalStars {
    var sum = 0;
    for (var i = 0; i < _stars.length; i++) {
      sum += _stars.codeUnitAt(i) - 0x30;
    }
    return sum;
  }

  bool get finishedAll => unlocked >= kTotalLevels && starsFor(kTotalLevels) > 0;

  Future<void> _save() async {
    await Future.wait(<Future<bool>>[
      _prefs.setInt('unlocked', unlocked),
      _prefs.setInt('coins', coins),
      _prefs.setInt('hints', hints),
      _prefs.setInt('undos', undos),
      _prefs.setInt('skips', skips),
      _prefs.setBool('sound', sound),
      _prefs.setBool('haptics', haptics),
      _prefs.setString('theme', themeId),
      _prefs.setStringList('themes', ownedThemes.toList()),
      _prefs.setString('stars', _stars),
    ]);
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  /// Records a win. Returns the coins earned.
  int completeLevel(int level, int stars) {
    final best = starsFor(level);
    if (stars > best) {
      _stars = _stars.replaceRange(level - 1, level, stars.toString());
    }
    if (level >= unlocked && level < kTotalLevels) unlocked = level + 1;
    final reward = 10 + stars * 5 + (best == 0 ? 5 : 0);
    coins += reward;
    levelsSinceAd++;
    _commit();
    return reward;
  }

  /// Skips [level] without winning it.
  void skipLevel(int level) {
    if (level >= unlocked && level < kTotalLevels) unlocked = level + 1;
    _commit();
  }

  bool useHint() {
    if (hints <= 0) return false;
    hints--;
    _commit();
    return true;
  }

  bool useUndo() {
    if (undos <= 0) return false;
    undos--;
    _commit();
    return true;
  }

  bool useSkip() {
    if (skips <= 0) return false;
    skips--;
    _commit();
    return true;
  }

  void addHints(int n) {
    hints += n;
    _commit();
  }

  void addUndos(int n) {
    undos += n;
    _commit();
  }

  void addSkips(int n) {
    skips += n;
    _commit();
  }

  void addCoins(int n) {
    coins += n;
    _commit();
  }

  bool spend(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    _commit();
    return true;
  }

  bool buyTheme(AppPalette p) {
    if (ownedThemes.contains(p.id)) return true;
    if (!spend(p.price)) return false;
    ownedThemes.add(p.id);
    themeId = p.id;
    _commit();
    return true;
  }

  void selectTheme(AppPalette p) {
    if (!ownedThemes.contains(p.id)) return;
    themeId = p.id;
    _commit();
  }

  void setSound(bool v) {
    sound = v;
    _commit();
  }

  void setHaptics(bool v) {
    haptics = v;
    _commit();
  }

  Future<void> reset() async {
    unlocked = 1;
    coins = 0;
    hints = 3;
    undos = 3;
    skips = 1;
    themeId = kNeon.id;
    ownedThemes = <String>{kNeon.id};
    _stars = '0' * kTotalLevels;
    levelsSinceAd = 0;
    notifyListeners();
    await _save();
  }
}

/// Makes [Progress] available to the widget tree and rebuilds dependents.
class ProgressScope extends InheritedNotifier<Progress> {
  const ProgressScope({
    super.key,
    required Progress progress,
    required super.child,
  }) : super(notifier: progress);

  static Progress of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'ProgressScope missing above this widget');
    return scope!.notifier!;
  }
}

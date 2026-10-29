import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'progress.dart';

/// Sound effects and haptics, gated by the player's settings.
class Fx {
  Fx._();

  static final Fx instance = Fx._();

  Progress? _progress;
  final Map<String, AudioPlayer> _players = <String, AudioPlayer>{};

  void attach(Progress progress) => _progress = progress;

  Future<void> _play(String name) async {
    if (_progress?.sound != true) return;
    try {
      final player = _players.putIfAbsent(name, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sfx/$name.wav'), volume: 0.8);
    } catch (e) {
      debugPrint('sfx "$name" failed: $e');
    }
  }

  void _haptic(Future<void> Function() f) {
    if (_progress?.haptics == true) f();
  }

  void click() {
    _play('click');
    _haptic(HapticFeedback.selectionClick);
  }

  void pop() {
    _play('pop');
    _haptic(HapticFeedback.lightImpact);
  }

  void error() {
    _play('error');
    _haptic(HapticFeedback.heavyImpact);
  }

  void win() {
    _play('win');
    _haptic(HapticFeedback.mediumImpact);
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import 'providers.dart';
import 'volume_notifier.dart';

/// Guarda os ids dos sons tocando no momento (permite reprodução simultânea).
/// Um id sai do conjunto quando o áudio termina naturalmente ou é parado.
class PlayingNotifier extends Notifier<Set<int>> {
  StreamSubscription<int>? _sub;

  @override
  Set<int> build() {
    final controller = ref.watch(audioControllerProvider);
    _sub = controller.onComplete.listen((id) {
      state = {...state}..remove(id);
    });
    ref.onDispose(() => _sub?.cancel());
    return {};
  }

  Future<void> play(Sound sound) async {
    final id = sound.id;
    if (id == null) return;
    final controller = ref.read(audioControllerProvider);
    // Reaplica o volume master a cada play (determinístico).
    await controller.setVolume(ref.read(masterVolumeProvider));
    await controller.play(id, sound.filePath, loop: sound.loop);
    state = {...state, id};
  }

  Future<void> stop(Sound sound) async {
    final id = sound.id;
    if (id == null) return;
    await ref.read(audioControllerProvider).stop(id);
    state = {...state}..remove(id);
  }

  /// Toca o som; se ele já estiver tocando, para (toggle).
  Future<void> toggle(Sound sound) {
    return state.contains(sound.id) ? stop(sound) : play(sound);
  }
}

final playingSoundsProvider =
    NotifierProvider<PlayingNotifier, Set<int>>(PlayingNotifier.new);

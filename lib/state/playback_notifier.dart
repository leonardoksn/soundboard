import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import 'providers.dart';
import 'volume_notifier.dart';

/// Guarda o id do som atualmente tocando (null = nada tocando).
/// Zera automaticamente quando o áudio termina.
class PlayingNotifier extends Notifier<int?> {
  StreamSubscription<void>? _sub;

  @override
  int? build() {
    final controller = ref.watch(audioControllerProvider);
    _sub = controller.onComplete.listen((_) => state = null);
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  Future<void> play(Sound sound) async {
    final controller = ref.read(audioControllerProvider);
    // Reaplica o volume master a cada play — torna a reprodução determinística
    // independente do estado interno do player.
    await controller.setVolume(ref.read(masterVolumeProvider));
    await controller.playFile(sound.filePath);
    state = sound.id;
  }

  Future<void> stop() async {
    await ref.read(audioControllerProvider).stop();
    state = null;
  }

  /// Toca o som; se ele já estiver tocando, para (comportamento de toggle).
  Future<void> toggle(Sound sound) {
    return state == sound.id ? stop() : play(sound);
  }
}

final playingSoundProvider =
    NotifierProvider<PlayingNotifier, int?>(PlayingNotifier.new);

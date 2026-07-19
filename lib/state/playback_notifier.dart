import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import 'providers.dart';

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
    await ref.read(audioControllerProvider).playFile(sound.filePath);
    state = sound.id;
  }
}

final playingSoundProvider =
    NotifierProvider<PlayingNotifier, int?>(PlayingNotifier.new);

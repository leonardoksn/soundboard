import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sound_repository.dart';
import '../models/sound.dart';
import 'audio_controller.dart';
import 'sounds_notifier.dart';

final soundRepositoryProvider = Provider<SoundRepository>(
  (ref) => throw UnimplementedError('soundRepositoryProvider deve ser sobrescrito em main'),
);

final audioControllerProvider = Provider<AudioController>((ref) {
  final controller = AudioController(AudioPlayersSoundPlayer());
  ref.onDispose(controller.dispose);
  return controller;
});

final soundsProvider =
    AsyncNotifierProvider<SoundsNotifier, List<Sound>>(SoundsNotifier.new);

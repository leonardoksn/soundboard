import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../state/playback_notifier.dart';
import '../state/providers.dart';
import 'add_edit_sound_sheet.dart';
import 'sound_button.dart';

class SoundboardScreen extends ConsumerWidget {
  const SoundboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundsAsync = ref.watch(soundsProvider);
    final playingId = ref.watch(playingSoundProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Soundboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditSoundSheet(context),
        child: const Icon(Icons.add),
      ),
      body: soundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar os sons'),
              TextButton(
                onPressed: () => ref.invalidate(soundsProvider),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
        data: (sounds) {
          if (sounds.isEmpty) {
            return const Center(
              child: Text('Nenhum som ainda.\nToque em + para importar.',
                  textAlign: TextAlign.center),
            );
          }
          return ReorderableGridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            onReorder: (oldIndex, newIndex) =>
                ref.read(soundsProvider.notifier).reorder(oldIndex, newIndex),
            children: [
              for (final sound in sounds)
                SoundButton(
                  key: ValueKey(sound.id),
                  sound: sound,
                  isPlaying: playingId == sound.id,
                  onTap: () =>
                      ref.read(playingSoundProvider.notifier).play(sound),
                  onEdit: () => showAddEditSoundSheet(context, existing: sound),
                ),
            ],
          );
        },
      ),
    );
  }
}

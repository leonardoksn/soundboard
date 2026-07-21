import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import 'providers.dart';

class SoundsNotifier extends AsyncNotifier<List<Sound>> {
  @override
  Future<List<Sound>> build() {
    return ref.read(soundRepositoryProvider).getAll();
  }

  Future<void> _refresh() async {
    final repo = ref.read(soundRepositoryProvider);
    state = await AsyncValue.guard(repo.getAll);
  }

  Future<void> add({
    required String sourceFilePath,
    required String name,
    required int color,
    bool loop = false,
  }) async {
    await ref.read(soundRepositoryProvider).add(
        sourceFilePath: sourceFilePath, name: name, color: color, loop: loop);
    await _refresh();
  }

  Future<void> rename(int id, String name) async {
    await ref.read(soundRepositoryProvider).rename(id, name);
    await _refresh();
  }

  Future<void> setLoop(int id, bool loop) async {
    await ref.read(soundRepositoryProvider).setLoop(id, loop);
    await _refresh();
  }

  Future<void> changeColor(int id, int color) async {
    await ref.read(soundRepositoryProvider).changeColor(id, color);
    await _refresh();
  }

  Future<void> remove(int id) async {
    await ref.read(soundRepositoryProvider).remove(id);
    await _refresh();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await ref.read(soundRepositoryProvider).reorder(oldIndex, newIndex);
    await _refresh();
  }
}

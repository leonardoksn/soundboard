import 'dart:async';

import 'package:soundboard/data/sound_repository.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/audio_controller.dart';

/// Player de áudio fake — registra chamadas e permite disparar onComplete.
class FakePlayer implements SoundPlayer {
  final List<String> calls = [];
  final StreamController<void> _complete = StreamController<void>.broadcast();

  @override
  Future<void> play(String path) async => calls.add('play:$path');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume:$volume');
  @override
  Future<void> dispose() async => calls.add('dispose');
  @override
  Stream<void> get onComplete => _complete.stream;

  /// Simula o término natural da reprodução.
  void complete() => _complete.add(null);
}

/// Repositório em memória para widget tests — evita I/O real de disco/SQLite,
/// cujos futuros não completam sob o fake-async do testWidgets.
class FakeSoundRepository implements SoundRepository {
  final List<Sound> _sounds;
  int _nextId;

  FakeSoundRepository([List<Sound>? initial])
      : _sounds = [...?initial],
        _nextId = (initial?.length ?? 0) + 1;

  @override
  Future<List<Sound>> getAll() async => List.of(_sounds);

  @override
  Future<Sound> add({
    required String sourceFilePath,
    required String name,
    required int color,
  }) async {
    final s = Sound(
      id: _nextId++,
      name: name,
      filePath: sourceFilePath,
      color: color,
      position: _sounds.length,
    );
    _sounds.add(s);
    return s;
  }

  @override
  Future<void> rename(int id, String name) async {
    final i = _sounds.indexWhere((s) => s.id == id);
    if (i >= 0) _sounds[i] = _sounds[i].copyWith(name: name);
  }

  @override
  Future<void> changeColor(int id, int color) async {
    final i = _sounds.indexWhere((s) => s.id == id);
    if (i >= 0) _sounds[i] = _sounds[i].copyWith(color: color);
  }

  @override
  Future<void> remove(int id) async => _sounds.removeWhere((s) => s.id == id);

  @override
  Future<void> reorder(int oldIndex, int newIndex) async {
    final m = _sounds.removeAt(oldIndex);
    _sounds.insert(newIndex, m);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

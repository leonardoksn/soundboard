import 'dart:async';

import 'package:soundboard/data/sound_repository.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/audio_controller.dart';
import 'package:soundboard/state/recorder.dart';

/// Gravador fake — registra chamadas e devolve permissão/caminho fixos.
class FakeRecorder implements Recorder {
  final bool permission;
  final String? stopPath;
  final List<String> calls = [];

  FakeRecorder({this.permission = true, this.stopPath});

  @override
  Future<bool> hasPermission() async {
    calls.add('perm');
    return permission;
  }

  @override
  Future<void> start(String path) async => calls.add('start');

  @override
  Future<String?> stop() async {
    calls.add('stop');
    return stopPath;
  }

  @override
  Future<void> dispose() async {}
}

/// Player de áudio fake — registra chamadas e permite disparar onComplete.
class FakePlayer implements SoundPlayer {
  final List<String> calls = [];
  final StreamController<int> _complete = StreamController<int>.broadcast();

  @override
  Future<void> play(int id, String path, {bool loop = false}) async =>
      calls.add('play:$id:$path${loop ? ':loop' : ''}');
  @override
  Future<void> stop(int id) async => calls.add('stop:$id');
  @override
  Future<void> stopAll() async => calls.add('stopAll');
  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume:$volume');
  @override
  Future<void> dispose() async => calls.add('dispose');
  @override
  Stream<int> get onComplete => _complete.stream;

  /// Simula o término natural da reprodução da voz [id].
  void complete(int id) => _complete.add(id);
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
    bool loop = false,
  }) async {
    final s = Sound(
      id: _nextId++,
      name: name,
      filePath: sourceFilePath,
      color: color,
      position: _sounds.length,
      loop: loop,
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
  Future<void> setLoop(int id, bool loop) async {
    final i = _sounds.indexWhere((s) => s.id == id);
    if (i >= 0) _sounds[i] = _sounds[i].copyWith(loop: loop);
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

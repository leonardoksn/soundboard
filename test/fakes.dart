import 'package:soundboard/data/sound_repository.dart';
import 'package:soundboard/models/sound.dart';

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

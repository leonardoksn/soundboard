import 'package:sqflite/sqflite.dart';
import '../models/sound.dart';
import 'database.dart';
import 'sound_file_storage.dart';

class SoundRepository {
  final Database db;
  final SoundFileStorage storage;

  SoundRepository({required this.db, required this.storage});

  Future<List<Sound>> getAll() async {
    final rows = await db.query(AppDatabase.table, orderBy: 'position ASC');
    return rows.map(Sound.fromMap).toList();
  }

  Future<Sound> add({
    required String sourceFilePath,
    required String name,
    required int color,
    bool loop = false,
  }) async {
    final newPath = await storage.importFile(sourceFilePath);
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(position) + 1, 0) AS next FROM ${AppDatabase.table}',
    );
    final position = result.first['next'] as int;
    final sound = Sound(
      name: name,
      filePath: newPath,
      color: color,
      position: position,
      loop: loop,
    );
    final id = await db.insert(AppDatabase.table, sound.toMap());
    return sound.copyWith(id: id);
  }

  Future<void> rename(int id, String name) async {
    await db.update(AppDatabase.table, {'name': name},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setLoop(int id, bool loop) async {
    await db.update(AppDatabase.table, {'loop': loop ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> changeColor(int id, int color) async {
    await db.update(AppDatabase.table, {'color': color},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> remove(int id) async {
    final rows = await db.query(AppDatabase.table,
        columns: ['file_path'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      await storage.deleteFile(rows.first['file_path'] as String);
    }
    await db.delete(AppDatabase.table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final sounds = await getAll();
    final moved = sounds.removeAt(oldIndex);
    sounds.insert(newIndex, moved);
    final batch = db.batch();
    for (var i = 0; i < sounds.length; i++) {
      batch.update(AppDatabase.table, {'position': i},
          where: 'id = ?', whereArgs: [sounds[i].id]);
    }
    await batch.commit(noResult: true);
  }
}

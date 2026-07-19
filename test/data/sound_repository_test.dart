import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soundboard/data/database.dart';
import 'package:soundboard/data/sound_file_storage.dart';
import 'package:soundboard/data/sound_repository.dart';

void main() {
  late Database db;
  late Directory tempRoot;
  late SoundRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.createSchema(db),
      ),
    );
    tempRoot = await Directory.systemTemp.createTemp('sb_repo_');
    repo = SoundRepository(
      db: db,
      storage: SoundFileStorage(Directory(p.join(tempRoot.path, 'sounds'))),
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  Future<String> makeSource(String name) async {
    final f = File(p.join(tempRoot.path, name));
    await f.writeAsBytes([1]);
    return f.path;
  }

  test('add insere com position sequencial e getAll retorna ordenado', () async {
    await repo.add(sourceFilePath: await makeSource('a.mp3'), name: 'A', color: 1);
    await repo.add(sourceFilePath: await makeSource('b.mp3'), name: 'B', color: 2);

    final all = await repo.getAll();
    expect(all.map((s) => s.name), ['A', 'B']);
    expect(all.map((s) => s.position), [0, 1]);
    expect(all[0].id, isNotNull);
  });

  test('rename e changeColor persistem', () async {
    final s = await repo.add(
        sourceFilePath: await makeSource('a.mp3'), name: 'A', color: 1);
    await repo.rename(s.id!, 'Novo');
    await repo.changeColor(s.id!, 999);

    final all = await repo.getAll();
    expect(all.single.name, 'Novo');
    expect(all.single.color, 999);
  });

  test('remove apaga registro e arquivo', () async {
    final s = await repo.add(
        sourceFilePath: await makeSource('a.mp3'), name: 'A', color: 1);
    expect(await File(s.filePath).exists(), isTrue);

    await repo.remove(s.id!);

    expect(await repo.getAll(), isEmpty);
    expect(await File(s.filePath).exists(), isFalse);
  });

  test('reorder move item e regrava positions', () async {
    await repo.add(sourceFilePath: await makeSource('a.mp3'), name: 'A', color: 1);
    await repo.add(sourceFilePath: await makeSource('b.mp3'), name: 'B', color: 2);
    await repo.add(sourceFilePath: await makeSource('c.mp3'), name: 'C', color: 3);

    await repo.reorder(0, 2);

    final all = await repo.getAll();
    expect(all.map((s) => s.name), ['B', 'C', 'A']);
    expect(all.map((s) => s.position), [0, 1, 2]);
  });
}

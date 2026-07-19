import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soundboard/data/database.dart';
import 'package:soundboard/data/sound_file_storage.dart';
import 'package:soundboard/data/sound_repository.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/providers.dart';

void main() {
  late Database db;
  late Directory tempRoot;
  late ProviderContainer container;

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
    tempRoot = await Directory.systemTemp.createTemp('sb_notifier_');
    final repo = SoundRepository(
      db: db,
      storage: SoundFileStorage(Directory(p.join(tempRoot.path, 'sounds'))),
    );
    container = ProviderContainer(
      overrides: [soundRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  Future<String> makeSource(String name) async {
    final f = File(p.join(tempRoot.path, name));
    await f.writeAsBytes([1]);
    return f.path;
  }

  Future<List<Sound>> read() async => container.read(soundsProvider.future);

  test('build comeca vazio; add reflete no estado', () async {
    expect(await read(), isEmpty);

    await container
        .read(soundsProvider.notifier)
        .add(sourceFilePath: await makeSource('a.mp3'), name: 'A', color: 1);

    final sounds = await read();
    expect(sounds.single.name, 'A');
  });

  test('remove tira do estado', () async {
    final notifier = container.read(soundsProvider.notifier);
    await notifier.add(
        sourceFilePath: await makeSource('a.mp3'), name: 'A', color: 1);
    final id = (await read()).single.id!;

    await notifier.remove(id);

    expect(await read(), isEmpty);
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundboard/data/sound_file_storage.dart';

void main() {
  late Directory tempRoot;
  late Directory baseDir;
  late SoundFileStorage storage;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('sb_test_');
    baseDir = Directory(p.join(tempRoot.path, 'sounds'));
    storage = SoundFileStorage(baseDir);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('importFile copia o arquivo, preserva extensao e conteudo', () async {
    final src = File(p.join(tempRoot.path, 'orig.mp3'));
    await src.writeAsBytes([1, 2, 3, 4]);

    final newPath = await storage.importFile(src.path);

    expect(p.extension(newPath), '.mp3');
    expect(p.dirname(newPath), baseDir.path);
    expect(await File(newPath).readAsBytes(), [1, 2, 3, 4]);
    expect(await src.exists(), isTrue);
  });

  test('deleteFile remove o arquivo e nao lanca se ja sumiu', () async {
    final src = File(p.join(tempRoot.path, 'orig.wav'));
    await src.writeAsBytes([9]);
    final newPath = await storage.importFile(src.path);

    await storage.deleteFile(newPath);
    expect(await File(newPath).exists(), isFalse);

    await storage.deleteFile(newPath);
  });
}

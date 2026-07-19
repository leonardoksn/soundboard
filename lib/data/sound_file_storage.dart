import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class SoundFileStorage {
  final Directory baseDir;
  final Uuid _uuid;

  SoundFileStorage(this.baseDir, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<String> importFile(String sourcePath) async {
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final destPath = p.join(baseDir.path, '${_uuid.v4()}$ext');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

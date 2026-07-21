import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String table = 'sounds';

  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $table (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT    NOT NULL,
        file_path TEXT    NOT NULL,
        color     INTEGER NOT NULL,
        position  INTEGER NOT NULL,
        loop      INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN loop INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<Database> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'soundboard.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => createSchema(db),
      onUpgrade: _migrate,
    );
  }
}

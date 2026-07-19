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
        position  INTEGER NOT NULL
      )
    ''');
  }

  static Future<Database> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'soundboard.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => createSchema(db),
    );
  }
}

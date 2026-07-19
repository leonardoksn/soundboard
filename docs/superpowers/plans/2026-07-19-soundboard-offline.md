# Soundboard Offline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir um app Android offline de soundboard onde o usuário importa
áudios do celular, cada um vira um botão numa grade, e tocar no botão reproduz o
som (um por vez).

**Architecture:** Três camadas — Dados (SQLite via `sqflite` + arquivos em disco),
Estado (Riverpod: `AsyncNotifier` + controlador de áudio), UI (grade de botões).
A UI nunca toca SQL nem arquivos diretamente; tudo passa pelo repositório e pelos
providers.

**Tech Stack:** Flutter/Dart, `flutter_riverpod`, `sqflite`, `audioplayers`,
`file_picker`, `path_provider`, `reorderable_grid_view`, `uuid`, `path`.
Testes: `flutter_test`, `sqflite_common_ffi` (SQLite em memória).

## Global Constraints

- Projeto: `soundboard`, applicationId `com.leonardo.soundboard`.
- Offline: nenhuma chamada de rede em nenhum ponto.
- Reprodução: **um som por vez** — tocar um novo interrompe o anterior.
- Arquivos de áudio importados são **copiados** para a pasta privada do app;
  o banco guarda só o caminho.
- `minSdkVersion` Android ≥ 23 (requisito do `audioplayers`).
- Cada arquivo em `lib/` tem uma responsabilidade única (ver estrutura na spec).
- TDD: todo código de lógica nasce de um teste que falha primeiro.
- Comandos assumem o CWD `~/projects/soundboard` e as variáveis de ambiente do
  Android/Flutter já carregadas (`source ~/.config/zsh/.zshrc`).

---

## File Structure

| Arquivo | Responsabilidade | Task |
|---------|------------------|------|
| `pubspec.yaml` | dependências | 1 |
| `android/app/build.gradle.kts` | minSdk | 1 |
| `lib/models/sound.dart` | modelo `Sound` imutável + (de)serialização | 2 |
| `lib/data/sound_file_storage.dart` | copiar/apagar arquivos de áudio | 3 |
| `lib/data/database.dart` | abrir SQLite + criar schema | 4 |
| `lib/data/sound_repository.dart` | CRUD + reorder | 4 |
| `lib/state/audio_controller.dart` | wrapper do player (stop→play) | 5 |
| `lib/state/providers.dart` | providers Riverpod | 6 |
| `lib/state/sounds_notifier.dart` | `AsyncNotifier<List<Sound>>` + ações | 6 |
| `lib/ui/sound_colors.dart` | paleta de cores presets | 7 |
| `lib/ui/sound_button.dart` | botão (play + ícone editar) | 7 |
| `lib/ui/add_edit_sound_sheet.dart` | bottom sheet importar/editar | 8 |
| `lib/ui/soundboard_screen.dart` | tela principal (grade + FAB) | 9 |
| `lib/main.dart` | bootstrap + ProviderScope | 10 |

---

## Task 1: Dependências e configuração do projeto

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`

**Interfaces:**
- Consumes: nada.
- Produces: os pacotes disponíveis para todas as tasks seguintes.

- [ ] **Step 1: Adicionar dependências**

Substitua a seção `dependencies:` e `dev_dependencies:` do `pubspec.yaml` por:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  sqflite: ^2.4.1
  path: ^1.9.0
  path_provider: ^2.1.5
  audioplayers: ^6.1.0
  file_picker: ^8.1.6
  reorderable_grid_view: ^2.2.8
  uuid: ^4.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  sqflite_common_ffi: ^2.3.4
```

- [ ] **Step 2: Ajustar minSdk do Android**

Em `android/app/build.gradle.kts`, dentro de `defaultConfig { ... }`, troque a
linha `minSdk = flutter.minSdkVersion` por:

```kotlin
        minSdk = 23
```

- [ ] **Step 3: Instalar e validar**

Run: `flutter pub get`
Expected: "Got dependencies!" sem erros.

Run: `flutter analyze`
Expected: "No issues found!" (o app ainda é o contador padrão).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/build.gradle.kts
git commit -m "chore: add dependencias e ajusta minSdk"
```

---

## Task 2: Modelo `Sound`

**Files:**
- Create: `lib/models/sound.dart`
- Test: `test/models/sound_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `class Sound` com campos `int? id`, `String name`, `String filePath`,
  `int color`, `int position`; construtor const nomeado; `Sound copyWith({...})`;
  `Map<String, Object?> toMap()`; `factory Sound.fromMap(Map<String, Object?>)`.
  `toMap()` NÃO inclui `id` quando é null (para o autoincrement do SQLite).

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/models/sound_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/models/sound.dart';

void main() {
  test('fromMap/toMap faz round-trip preservando os campos', () {
    final map = {
      'id': 1,
      'name': 'Risada',
      'file_path': '/dados/sounds/abc.mp3',
      'color': 0xFFEF5350,
      'position': 2,
    };
    final sound = Sound.fromMap(map);
    expect(sound.id, 1);
    expect(sound.name, 'Risada');
    expect(sound.filePath, '/dados/sounds/abc.mp3');
    expect(sound.color, 0xFFEF5350);
    expect(sound.position, 2);
    expect(sound.toMap(), map);
  });

  test('toMap omite id quando null', () {
    const sound = Sound(
      name: 'Novo',
      filePath: '/x.mp3',
      color: 0xFF000000,
      position: 0,
    );
    expect(sound.toMap().containsKey('id'), isFalse);
  });

  test('copyWith troca apenas o campo informado', () {
    const sound = Sound(
      id: 5,
      name: 'A',
      filePath: '/a.mp3',
      color: 1,
      position: 0,
    );
    final renamed = sound.copyWith(name: 'B');
    expect(renamed.name, 'B');
    expect(renamed.id, 5);
    expect(renamed.filePath, '/a.mp3');
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/models/sound_test.dart`
Expected: FALHA — `Sound` não existe / não compila.

- [ ] **Step 3: Implementar o modelo**

```dart
// lib/models/sound.dart
class Sound {
  final int? id;
  final String name;
  final String filePath;
  final int color;
  final int position;

  const Sound({
    this.id,
    required this.name,
    required this.filePath,
    required this.color,
    required this.position,
  });

  Sound copyWith({
    int? id,
    String? name,
    String? filePath,
    int? color,
    int? position,
  }) {
    return Sound(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      color: color ?? this.color,
      position: position ?? this.position,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'file_path': filePath,
      'color': color,
      'position': position,
    };
  }

  factory Sound.fromMap(Map<String, Object?> map) {
    return Sound(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      color: map['color'] as int,
      position: map['position'] as int,
    );
  }
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/models/sound_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/models/sound.dart test/models/sound_test.dart
git commit -m "feat: add modelo Sound com (de)serializacao"
```

---

## Task 3: `SoundFileStorage` (copiar/apagar arquivos)

**Files:**
- Create: `lib/data/sound_file_storage.dart`
- Test: `test/data/sound_file_storage_test.dart`

**Interfaces:**
- Consumes: pacotes `path`, `uuid`, `dart:io`.
- Produces:
  - `class SoundFileStorage`, construtor `SoundFileStorage(Directory baseDir)`
    (injeta a pasta; em produção será `.../app_documents/sounds`).
  - `Future<String> importFile(String sourcePath)` — copia o arquivo pra
    `baseDir/<uuid><ext>`, cria `baseDir` se não existir, retorna o caminho novo.
  - `Future<void> deleteFile(String filePath)` — apaga o arquivo se existir
    (não lança se já sumiu).

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/data/sound_file_storage_test.dart
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
    // o original continua intacto (foi copia, nao move)
    expect(await src.exists(), isTrue);
  });

  test('deleteFile remove o arquivo e nao lanca se ja sumiu', () async {
    final src = File(p.join(tempRoot.path, 'orig.wav'));
    await src.writeAsBytes([9]);
    final newPath = await storage.importFile(src.path);

    await storage.deleteFile(newPath);
    expect(await File(newPath).exists(), isFalse);

    // segunda chamada nao deve lançar
    await storage.deleteFile(newPath);
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/data/sound_file_storage_test.dart`
Expected: FALHA — `SoundFileStorage` não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/data/sound_file_storage.dart
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
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/data/sound_file_storage_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/data/sound_file_storage.dart test/data/sound_file_storage_test.dart
git commit -m "feat: add SoundFileStorage para copiar/apagar audios"
```

---

## Task 4: `AppDatabase` + `SoundRepository`

**Files:**
- Create: `lib/data/database.dart`
- Create: `lib/data/sound_repository.dart`
- Test: `test/data/sound_repository_test.dart`

**Interfaces:**
- Consumes: `Sound` (Task 2), `SoundFileStorage` (Task 3), `sqflite`.
- Produces:
  - `class AppDatabase` com `static const table = 'sounds'`,
    `static Future<void> createSchema(Database db)` e
    `static Future<Database> open()` (usa `path_provider` + `sqflite`, só
    produção).
  - `class SoundRepository`, construtor
    `SoundRepository({required Database db, required SoundFileStorage storage})`.
  - Métodos:
    - `Future<List<Sound>> getAll()` — ordenado por `position ASC`.
    - `Future<Sound> add({required String sourceFilePath, required String name, required int color})`
      — copia arquivo, calcula próxima `position` (fim da lista), insere,
      retorna o `Sound` com `id`.
    - `Future<void> rename(int id, String name)`
    - `Future<void> changeColor(int id, int color)`
    - `Future<void> remove(int id)` — apaga registro e o arquivo.
    - `Future<void> reorder(int oldIndex, int newIndex)` — move o item na ordem
      e regrava `position` de todos.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/data/sound_repository_test.dart
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

    await repo.reorder(0, 2); // move A para o fim

    final all = await repo.getAll();
    expect(all.map((s) => s.name), ['B', 'C', 'A']);
    expect(all.map((s) => s.position), [0, 1, 2]);
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/data/sound_repository_test.dart`
Expected: FALHA — classes não existem.

- [ ] **Step 3: Implementar `AppDatabase`**

```dart
// lib/data/database.dart
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
```

- [ ] **Step 4: Implementar `SoundRepository`**

```dart
// lib/data/sound_repository.dart
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
    );
    final id = await db.insert(AppDatabase.table, sound.toMap());
    return sound.copyWith(id: id);
  }

  Future<void> rename(int id, String name) async {
    await db.update(AppDatabase.table, {'name': name},
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
```

- [ ] **Step 5: Rodar e confirmar que passa**

Run: `flutter test test/data/sound_repository_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 6: Commit**

```bash
git add lib/data/database.dart lib/data/sound_repository.dart test/data/sound_repository_test.dart
git commit -m "feat: add AppDatabase e SoundRepository com CRUD e reorder"
```

---

## Task 5: `AudioController` (stop → play)

**Files:**
- Create: `lib/state/audio_controller.dart`
- Test: `test/state/audio_controller_test.dart`

**Interfaces:**
- Consumes: pacote `audioplayers` (só na implementação concreta).
- Produces:
  - `abstract class SoundPlayer` com `Future<void> play(String path)`,
    `Future<void> stop()`, `Future<void> dispose()`.
  - `class AudioPlayersSoundPlayer implements SoundPlayer` — usa
    `audioplayers.AudioPlayer` e `DeviceFileSource`.
  - `class AudioController`, construtor `AudioController(SoundPlayer player)`,
    com `Future<void> playFile(String path)` (chama `stop()` e depois
    `play(path)`) e `Future<void> dispose()`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/state/audio_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/state/audio_controller.dart';

class FakeSoundPlayer implements SoundPlayer {
  final List<String> calls = [];
  @override
  Future<void> play(String path) async => calls.add('play:$path');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  test('playFile chama stop antes de play (interrompe o anterior)', () async {
    final fake = FakeSoundPlayer();
    final controller = AudioController(fake);

    await controller.playFile('/a.mp3');

    expect(fake.calls, ['stop', 'play:/a.mp3']);
  });

  test('dispose repassa para o player', () async {
    final fake = FakeSoundPlayer();
    await AudioController(fake).dispose();
    expect(fake.calls, contains('dispose'));
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/state/audio_controller_test.dart`
Expected: FALHA — `AudioController`/`SoundPlayer` não existem.

- [ ] **Step 3: Implementar**

```dart
// lib/state/audio_controller.dart
import 'package:audioplayers/audioplayers.dart';

abstract class SoundPlayer {
  Future<void> play(String path);
  Future<void> stop();
  Future<void> dispose();
}

class AudioPlayersSoundPlayer implements SoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class AudioController {
  final SoundPlayer _player;

  AudioController(this._player);

  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(path);
  }

  Future<void> dispose() => _player.dispose();
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/state/audio_controller_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/state/audio_controller.dart test/state/audio_controller_test.dart
git commit -m "feat: add AudioController com comportamento stop-then-play"
```

---

## Task 6: Providers Riverpod + `SoundsNotifier`

**Files:**
- Create: `lib/state/providers.dart`
- Create: `lib/state/sounds_notifier.dart`
- Test: `test/state/sounds_notifier_test.dart`

**Interfaces:**
- Consumes: `Sound`, `SoundRepository`, `AudioController` (tasks anteriores),
  `flutter_riverpod`.
- Produces:
  - Em `providers.dart`:
    - `final soundRepositoryProvider = Provider<SoundRepository>((ref) => throw UnimplementedError('override em main'));`
    - `final audioControllerProvider = Provider<AudioController>((ref) {...})`
      (cria `AudioController(AudioPlayersSoundPlayer())`, registra
      `ref.onDispose`).
    - `final soundsProvider = AsyncNotifierProvider<SoundsNotifier, List<Sound>>(SoundsNotifier.new);`
  - Em `sounds_notifier.dart`: `class SoundsNotifier extends AsyncNotifier<List<Sound>>`
    com `build()` (carrega do repo) e ações `add`, `rename`, `changeColor`,
    `remove`, `reorder` — cada uma persiste via repo e recarrega o estado.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/state/sounds_notifier_test.dart
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

  Future<List<Sound>> read() async =>
      container.read(soundsProvider.future);

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
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/state/sounds_notifier_test.dart`
Expected: FALHA — providers/notifier não existem.

- [ ] **Step 3: Implementar `sounds_notifier.dart`**

```dart
// lib/state/sounds_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import 'providers.dart';

class SoundsNotifier extends AsyncNotifier<List<Sound>> {
  @override
  Future<List<Sound>> build() {
    return ref.read(soundRepositoryProvider).getAll();
  }

  Future<void> _refresh() async {
    final repo = ref.read(soundRepositoryProvider);
    state = await AsyncValue.guard(repo.getAll);
  }

  Future<void> add({
    required String sourceFilePath,
    required String name,
    required int color,
  }) async {
    await ref
        .read(soundRepositoryProvider)
        .add(sourceFilePath: sourceFilePath, name: name, color: color);
    await _refresh();
  }

  Future<void> rename(int id, String name) async {
    await ref.read(soundRepositoryProvider).rename(id, name);
    await _refresh();
  }

  Future<void> changeColor(int id, int color) async {
    await ref.read(soundRepositoryProvider).changeColor(id, color);
    await _refresh();
  }

  Future<void> remove(int id) async {
    await ref.read(soundRepositoryProvider).remove(id);
    await _refresh();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await ref.read(soundRepositoryProvider).reorder(oldIndex, newIndex);
    await _refresh();
  }
}
```

- [ ] **Step 4: Implementar `providers.dart`**

```dart
// lib/state/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sound_repository.dart';
import '../models/sound.dart';
import 'audio_controller.dart';
import 'sounds_notifier.dart';

final soundRepositoryProvider = Provider<SoundRepository>(
  (ref) => throw UnimplementedError('soundRepositoryProvider deve ser sobrescrito em main'),
);

final audioControllerProvider = Provider<AudioController>((ref) {
  final controller = AudioController(AudioPlayersSoundPlayer());
  ref.onDispose(controller.dispose);
  return controller;
});

final soundsProvider =
    AsyncNotifierProvider<SoundsNotifier, List<Sound>>(SoundsNotifier.new);
```

- [ ] **Step 5: Rodar e confirmar que passa**

Run: `flutter test test/state/sounds_notifier_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 6: Commit**

```bash
git add lib/state/providers.dart lib/state/sounds_notifier.dart test/state/sounds_notifier_test.dart
git commit -m "feat: add providers Riverpod e SoundsNotifier"
```

---

## Task 7: `SoundButton` + paleta de cores

**Files:**
- Create: `lib/ui/sound_colors.dart`
- Create: `lib/ui/sound_button.dart`
- Test: `test/ui/sound_button_test.dart`

**Interfaces:**
- Consumes: `Sound` (Task 2), Flutter Material.
- Produces:
  - Em `sound_colors.dart`: `const List<int> kSoundColors` (8 cores ARGB).
  - `class SoundButton extends StatelessWidget`, construtor
    `SoundButton({required Sound sound, required VoidCallback onTap, required VoidCallback onEdit})`.
    Mostra o `name`, pinta o fundo com `Color(sound.color)`, e exibe um
    `IconButton` (ícone `Icons.edit`) no canto que chama `onEdit`. Toque no
    corpo chama `onTap`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/ui/sound_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/ui/sound_button.dart';

void main() {
  const sound = Sound(
    id: 1,
    name: 'Risada',
    filePath: '/a.mp3',
    color: 0xFFEF5350,
    position: 0,
  );

  testWidgets('mostra o nome e dispara onTap/onEdit', (tester) async {
    var tapped = 0;
    var edited = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoundButton(
          sound: sound,
          onTap: () => tapped++,
          onEdit: () => edited++,
        ),
      ),
    ));

    expect(find.text('Risada'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    expect(edited, 1);
    expect(tapped, 0);

    await tester.tap(find.text('Risada'));
    await tester.pump();
    expect(tapped, 1);
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/ui/sound_button_test.dart`
Expected: FALHA — `SoundButton` não existe.

- [ ] **Step 3: Implementar a paleta**

```dart
// lib/ui/sound_colors.dart
const List<int> kSoundColors = [
  0xFFEF5350, // vermelho
  0xFFAB47BC, // roxo
  0xFF5C6BC0, // indigo
  0xFF29B6F6, // azul
  0xFF26A69A, // teal
  0xFF66BB6A, // verde
  0xFFFFCA28, // amarelo
  0xFFFF7043, // laranja
];
```

- [ ] **Step 4: Implementar `SoundButton`**

```dart
// lib/ui/sound_button.dart
import 'package:flutter/material.dart';
import '../models/sound.dart';

class SoundButton extends StatelessWidget {
  final Sound sound;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const SoundButton({
    super.key,
    required this.sound,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(sound.color);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  sound.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Rodar e confirmar que passa**

Run: `flutter test test/ui/sound_button_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/sound_colors.dart lib/ui/sound_button.dart test/ui/sound_button_test.dart
git commit -m "feat: add SoundButton e paleta de cores"
```

---

## Task 8: `AddEditSoundSheet` (importar/editar)

**Files:**
- Create: `lib/ui/add_edit_sound_sheet.dart`
- Test: `test/ui/add_edit_sound_sheet_test.dart`

**Interfaces:**
- Consumes: `Sound`, `kSoundColors`, `soundsProvider` (via Riverpod),
  `file_picker`.
- Produces:
  - `typedef FilePickerFn = Future<String?> Function();` (retorna o caminho do
    arquivo escolhido ou null se cancelado) — injetável para testes.
  - `final filePickerProvider = Provider<FilePickerFn>((ref) {...})` — default
    usa `FilePicker.platform.pickFiles` (filtro `FileType.audio`) e retorna
    `result?.files.single.path`.
  - `const int kSoundColorsFirst` — primeira cor da paleta (default).
  - `Future<void> showAddEditSoundSheet(BuildContext context, {Sound? existing})`
    — abre um `showModalBottomSheet` com o formulário. Em modo novo
    (`existing == null`): botão "Escolher arquivo" (usa `filePickerProvider`),
    campo nome, seletor de cor, botão Salvar (chama `soundsProvider.add`). Em
    modo edição: campo nome + cor + botão Salvar (chama `rename`/`changeColor`)
    + botão Excluir (com confirmação → `remove`).

**Nota de teste:** o widget test cobre o modo edição (renomear), que não depende
do `file_picker`. O fluxo de importação é validado manualmente no dispositivo
(Task 10), pois depende do seletor nativo.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/ui/add_edit_sound_sheet_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soundboard/data/database.dart';
import 'package:soundboard/data/sound_file_storage.dart';
import 'package:soundboard/data/sound_repository.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/ui/add_edit_sound_sheet.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('modo edicao renomeia o som', (tester) async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.createSchema(db),
      ),
    );
    final tempRoot = await Directory.systemTemp.createTemp('sb_sheet_');
    final repo = SoundRepository(
      db: db,
      storage: SoundFileStorage(Directory(p.join(tempRoot.path, 'sounds'))),
    );
    final src = File(p.join(tempRoot.path, 'a.mp3'));
    await src.writeAsBytes([1]);
    final sound = await repo.add(
        sourceFilePath: src.path, name: 'Velho', color: kSoundColorsFirst);

    await tester.pumpWidget(ProviderScope(
      overrides: [soundRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddEditSoundSheet(context, existing: sound),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Novo');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final all = await repo.getAll();
    expect(all.single.name, 'Novo');

    await db.close();
    await tempRoot.delete(recursive: true);
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/ui/add_edit_sound_sheet_test.dart`
Expected: FALHA — `showAddEditSoundSheet`/`kSoundColorsFirst` não existem.

- [ ] **Step 3: Implementar**

```dart
// lib/ui/add_edit_sound_sheet.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import '../state/providers.dart';
import 'sound_colors.dart';

/// Primeira cor da paleta (usada como default).
const int kSoundColorsFirst = 0xFFEF5350;

typedef FilePickerFn = Future<String?> Function();

final filePickerProvider = Provider<FilePickerFn>((ref) {
  return () async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    return result?.files.single.path;
  };
});

Future<void> showAddEditSoundSheet(
  BuildContext context, {
  Sound? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SoundForm(existing: existing),
    ),
  );
}

class _SoundForm extends ConsumerStatefulWidget {
  final Sound? existing;
  const _SoundForm({this.existing});

  @override
  ConsumerState<_SoundForm> createState() => _SoundFormState();
}

class _SoundFormState extends ConsumerState<_SoundForm> {
  late final TextEditingController _nameController;
  late int _color;
  String? _pickedPath;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color ?? kSoundColorsFirst;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final path = await ref.read(filePickerProvider)();
    if (path != null) setState(() => _pickedPath = path);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(soundsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_isEditing) {
      final id = widget.existing!.id!;
      await notifier.rename(id, name);
      await notifier.changeColor(id, _color);
    } else {
      if (_pickedPath == null) return;
      try {
        await notifier.add(
            sourceFilePath: _pickedPath!, name: name, color: _color);
      } catch (_) {
        messenger.showSnackBar(
            const SnackBar(content: Text('não foi possível importar')));
        return;
      }
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir som?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(soundsProvider.notifier).remove(widget.existing!.id!);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? 'Editar som' : 'Novo som',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (!_isEditing)
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.audiotrack),
              label: Text(_pickedPath == null
                  ? 'Escolher arquivo'
                  : 'Arquivo selecionado'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final c in kSoundColors)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    backgroundColor: Color(c),
                    child: _color == c
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Salvar')),
          if (_isEditing)
            TextButton(
              onPressed: _delete,
              child: const Text('Excluir',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/ui/add_edit_sound_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/add_edit_sound_sheet.dart test/ui/add_edit_sound_sheet_test.dart
git commit -m "feat: add AddEditSoundSheet para importar/editar/excluir"
```

---

## Task 9: `SoundboardScreen` (grade + FAB)

**Files:**
- Create: `lib/ui/soundboard_screen.dart`
- Test: `test/ui/soundboard_screen_test.dart`

**Interfaces:**
- Consumes: `soundsProvider`, `audioControllerProvider`, `SoundButton`,
  `showAddEditSoundSheet`, `ReorderableGridView`.
- Produces: `class SoundboardScreen extends ConsumerWidget` — AppBar "Soundboard",
  corpo com estados loading/erro/vazio/grade, FAB `+` que chama
  `showAddEditSoundSheet(context)`. Cada `SoundButton`: `onTap` →
  `audioControllerProvider.playFile`; `onEdit` → `showAddEditSoundSheet(existing:)`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/ui/soundboard_screen_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soundboard/data/database.dart';
import 'package:soundboard/data/sound_file_storage.dart';
import 'package:soundboard/data/sound_repository.dart';
import 'package:soundboard/state/audio_controller.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/ui/soundboard_screen.dart';

class FakeSoundPlayer implements SoundPlayer {
  final List<String> played = [];
  @override
  Future<void> play(String path) async => played.add(path);
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('lista sons e toque dispara playFile', (tester) async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.createSchema(db),
      ),
    );
    final tempRoot = await Directory.systemTemp.createTemp('sb_screen_');
    final repo = SoundRepository(
      db: db,
      storage: SoundFileStorage(Directory(p.join(tempRoot.path, 'sounds'))),
    );
    final src = File(p.join(tempRoot.path, 'a.mp3'));
    await src.writeAsBytes([1]);
    await repo.add(sourceFilePath: src.path, name: 'Risada', color: 0xFFEF5350);

    final fakePlayer = FakeSoundPlayer();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        soundRepositoryProvider.overrideWithValue(repo),
        audioControllerProvider.overrideWithValue(AudioController(fakePlayer)),
      ],
      child: const MaterialApp(home: SoundboardScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Risada'), findsOneWidget);

    await tester.tap(find.text('Risada'));
    await tester.pump();

    expect(fakePlayer.played, hasLength(1));

    await db.close();
    await tempRoot.delete(recursive: true);
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/ui/soundboard_screen_test.dart`
Expected: FALHA — `SoundboardScreen` não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/ui/soundboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../state/providers.dart';
import 'add_edit_sound_sheet.dart';
import 'sound_button.dart';

class SoundboardScreen extends ConsumerWidget {
  const SoundboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundsAsync = ref.watch(soundsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Soundboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditSoundSheet(context),
        child: const Icon(Icons.add),
      ),
      body: soundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar os sons'),
              TextButton(
                onPressed: () => ref.invalidate(soundsProvider),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
        data: (sounds) {
          if (sounds.isEmpty) {
            return const Center(
              child: Text('Nenhum som ainda.\nToque em + para importar.',
                  textAlign: TextAlign.center),
            );
          }
          return ReorderableGridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            onReorder: (oldIndex, newIndex) =>
                ref.read(soundsProvider.notifier).reorder(oldIndex, newIndex),
            children: [
              for (final sound in sounds)
                SoundButton(
                  key: ValueKey(sound.id),
                  sound: sound,
                  onTap: () => ref
                      .read(audioControllerProvider)
                      .playFile(sound.filePath),
                  onEdit: () =>
                      showAddEditSoundSheet(context, existing: sound),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/ui/soundboard_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/soundboard_screen.dart test/ui/soundboard_screen_test.dart
git commit -m "feat: add SoundboardScreen com grade, reorder e FAB"
```

---

## Task 10: `main.dart` (bootstrap) + validação no dispositivo

**Files:**
- Modify: `lib/main.dart` (substituir o conteúdo do scaffold)

**Interfaces:**
- Consumes: `AppDatabase`, `SoundFileStorage`, `SoundRepository`, providers,
  `SoundboardScreen`, `path_provider`.
- Produces: função `main()` que inicializa o banco/armazenamento, sobrescreve
  `soundRepositoryProvider` e roda o app.

- [ ] **Step 1: Reescrever `lib/main.dart`**

```dart
// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'data/database.dart';
import 'data/sound_file_storage.dart';
import 'data/sound_repository.dart';
import 'state/providers.dart';
import 'ui/soundboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final docsDir = await getApplicationDocumentsDirectory();
  final storage = SoundFileStorage(Directory(p.join(docsDir.path, 'sounds')));
  final repository = SoundRepository(db: db, storage: storage);

  runApp(
    ProviderScope(
      overrides: [soundRepositoryProvider.overrideWithValue(repository)],
      child: const SoundboardApp(),
    ),
  );
}

class SoundboardApp extends StatelessWidget {
  const SoundboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SoundboardScreen(),
    );
  }
}
```

- [ ] **Step 2: Analisar e rodar toda a suíte de testes**

Run: `flutter analyze`
Expected: "No issues found!"

Run: `flutter test`
Expected: todos os testes das tasks 2–9 passam.

- [ ] **Step 3: Rodar no dispositivo físico (validação manual)**

Run: `flutter run -d RQCX800Q75J`

Verifique manualmente (critérios de sucesso da spec):
1. App abre mostrando "Nenhum som ainda".
2. FAB `+` → escolher um MP3 do celular → dar nome/cor → Salvar → botão aparece.
3. Tocar no botão reproduz o áudio; tocar outro interrompe o anterior.
4. Ícone de edição → renomear/trocar cor → persiste.
5. Ícone de edição → Excluir → some.
6. Arrastar botões reordena.
7. Fechar e reabrir o app: os sons continuam lá.
8. Ativar modo avião e confirmar que tudo funciona (offline).

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: bootstrap do app com banco, providers e SoundboardScreen"
```

---

## Self-Review (feito na escrita do plano)

- **Cobertura da spec:** origem=importar (T8/T10), grade única (T9), um som por
  vez (T5), nomear/excluir/cor/reordenar (T4/T6/T8/T9), ícone de edição (T7/T8),
  cópia de arquivos (T3), SQLite (T4), Riverpod (T6), erros (T8/T9), testes
  (todas), critérios de sucesso (T10). ✔
- **Sem placeholders:** todo passo tem código/comandos reais. ✔
- **Consistência de tipos:** `SoundRepository({db, storage})`,
  `add(sourceFilePath/name/color)`, `AudioController.playFile`,
  `showAddEditSoundSheet(context, {existing})`, `kSoundColors`/`kSoundColorsFirst`
  usados de forma idêntica entre tasks. ✔

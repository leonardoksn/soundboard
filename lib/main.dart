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

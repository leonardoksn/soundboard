import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/ui/add_edit_sound_sheet.dart';
import '../fakes.dart';

void main() {
  testWidgets('modo edicao renomeia o som', (tester) async {
    const sound = Sound(
      id: 1,
      name: 'Velho',
      filePath: '/a.mp3',
      color: kSoundColorsFirst,
      position: 0,
    );
    final repo = FakeSoundRepository([sound]);

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
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/l10n/app_localizations.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/state/recorder.dart';
import 'package:soundboard/ui/add_edit_sound_sheet.dart';
import '../fakes.dart';

Widget _host(FakeRecorder recorder) {
  return ProviderScope(
    overrides: [
      soundRepositoryProvider.overrideWithValue(FakeSoundRepository()),
      recorderProvider.overrideWithValue(recorder),
    ],
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAddEditSoundSheet(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sem permissão de microfone mostra aviso e não grava',
      (tester) async {
    final recorder = FakeRecorder(permission: false);
    await tester.pumpWidget(_host(recorder));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // botão GRAVAR visível no sheet de novo som
    expect(find.text('GRAVAR'), findsOneWidget);

    await tester.tap(find.text('GRAVAR'));
    await tester.pump();

    expect(recorder.calls, ['perm']);
    expect(find.text('Permissão de microfone negada'), findsOneWidget);
  });
}

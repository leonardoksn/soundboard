import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundboard/l10n/app_localizations.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/audio_controller.dart';
import 'package:soundboard/state/locale_notifier.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/ui/sound_button.dart';
import 'package:soundboard/ui/soundboard_screen.dart';
import '../fakes.dart';

Future<Widget> _app(FakeSoundRepository repo, FakePlayer player) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      soundRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioControllerProvider.overrideWithValue(AudioController(player)),
    ],
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SoundboardScreen(),
    ),
  );
}

FakeSoundRepository _repo() => FakeSoundRepository([
      const Sound(
          id: 1,
          name: 'Risada',
          filePath: '/a.mp3',
          color: 0xFFEF5350,
          position: 0),
    ]);

void main() {
  testWidgets('lista sons e toque toca; tocar de novo para', (tester) async {
    final player = FakePlayer();
    await tester.pumpWidget(await _app(_repo(), player));
    await tester.pumpAndSettle();

    expect(find.text('RISADA'), findsOneWidget);

    // primeiro toque toca (toca no pad, não no texto — o visor também
    // passa a exibir o nome quando toca)
    await tester.tap(find.byType(SoundButton));
    await tester.pump();
    expect(player.calls.where((c) => c.startsWith('play:')), hasLength(1));

    // segundo toque para (toggle)
    await tester.tap(find.byType(SoundButton));
    await tester.pump();
    expect(player.calls.any((c) => c.startsWith('stop:')), isTrue);
  });

  testWidgets('fader de volume (LEVEL) aparece na faceplate', (tester) async {
    await tester.pumpWidget(await _app(_repo(), FakePlayer()));
    await tester.pumpAndSettle();

    // locale pt → rótulo "NÍVEL"
    expect(find.text('NÍVEL'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/audio_controller.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/ui/soundboard_screen.dart';
import '../fakes.dart';

class FakeSoundPlayer implements SoundPlayer {
  final List<String> played = [];
  @override
  Future<void> play(String path) async => played.add(path);
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
  @override
  Stream<void> get onComplete => Stream<void>.empty();
}

void main() {
  testWidgets('lista sons e toque dispara playFile', (tester) async {
    final repo = FakeSoundRepository([
      const Sound(
          id: 1,
          name: 'Risada',
          filePath: '/a.mp3',
          color: 0xFFEF5350,
          position: 0),
    ]);
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
  });
}

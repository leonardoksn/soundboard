import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/state/audio_controller.dart';
import 'package:soundboard/state/locale_notifier.dart';
import 'package:soundboard/state/playback_notifier.dart';
import 'package:soundboard/state/providers.dart';
import '../fakes.dart';

const _s1 = Sound(id: 1, name: 'A', filePath: '/a.mp3', color: 0, position: 0);
const _s2 = Sound(id: 2, name: 'B', filePath: '/b.mp3', color: 0, position: 1);
const _loopSound =
    Sound(id: 3, name: 'C', filePath: '/c.mp3', color: 0, position: 2, loop: true);

Future<ProviderContainer> _container(FakePlayer fake) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    audioControllerProvider.overrideWithValue(AudioController(fake)),
  ]);
}

void main() {
  test('play adiciona o id ao conjunto tocando', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundsProvider.notifier).play(_s1);

    expect(c.read(playingSoundsProvider), {1});
    expect(fake.calls, contains('play:1:/a.mp3'));
  });

  test('sons diferentes tocam simultaneamente', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundsProvider.notifier).play(_s1);
    await c.read(playingSoundsProvider.notifier).toggle(_s2);

    expect(c.read(playingSoundsProvider), {1, 2});
  });

  test('toggle no mesmo som para (remove do conjunto, stop chamado)', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundsProvider.notifier).play(_s1);
    await c.read(playingSoundsProvider.notifier).toggle(_s1);

    expect(c.read(playingSoundsProvider), isEmpty);
    expect(fake.calls, contains('stop:1'));
  });

  test('play repassa a flag de loop', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundsProvider.notifier).play(_loopSound);

    expect(fake.calls, contains('play:3:/c.mp3:loop'));
  });

  test('remover um som tocando (em loop) interrompe a reprodução', () async {
    final fake = FakePlayer();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeSoundRepository([_loopSound]);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioControllerProvider.overrideWithValue(AudioController(fake)),
      soundRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);

    await c.read(soundsProvider.future);
    await c.read(playingSoundsProvider.notifier).play(_loopSound);
    expect(c.read(playingSoundsProvider), {3});

    await c.read(soundsProvider.notifier).remove(3);

    expect(c.read(playingSoundsProvider), isEmpty);
    expect(fake.calls, contains('stop:3'));
  });

  test('onComplete remove apenas o id que terminou', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundsProvider.notifier).play(_s1);
    await c.read(playingSoundsProvider.notifier).play(_s2);
    expect(c.read(playingSoundsProvider), {1, 2});

    fake.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(playingSoundsProvider), {2});
  });
}

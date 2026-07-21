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

Future<ProviderContainer> _container(FakePlayer fake) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    audioControllerProvider.overrideWithValue(AudioController(fake)),
  ]);
}

void main() {
  test('play define o id tocando e toca o arquivo', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundProvider.notifier).play(_s1);

    expect(c.read(playingSoundProvider), 1);
    expect(fake.calls, contains('play:/a.mp3'));
  });

  test('toggle no mesmo som para (state=null, stop chamado)', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundProvider.notifier).play(_s1);
    await c.read(playingSoundProvider.notifier).toggle(_s1);

    expect(c.read(playingSoundProvider), isNull);
    expect(fake.calls, contains('stop'));
  });

  test('toggle em som diferente troca a reprodução', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundProvider.notifier).play(_s1);
    await c.read(playingSoundProvider.notifier).toggle(_s2);

    expect(c.read(playingSoundProvider), 2);
  });

  test('onComplete zera o estado', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(playingSoundProvider.notifier).play(_s1);
    expect(c.read(playingSoundProvider), 1);

    fake.complete();
    await Future<void>.delayed(Duration.zero);

    expect(c.read(playingSoundProvider), isNull);
  });
}

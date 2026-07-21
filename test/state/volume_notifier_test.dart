import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundboard/state/audio_controller.dart';
import 'package:soundboard/state/locale_notifier.dart';
import 'package:soundboard/state/providers.dart';
import 'package:soundboard/state/volume_notifier.dart';
import '../fakes.dart';

Future<ProviderContainer> _container(
  FakePlayer fake, [
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    audioControllerProvider.overrideWithValue(AudioController(fake)),
  ]);
}

void main() {
  test('default é 1.0 quando não há preferência', () async {
    final c = await _container(FakePlayer());
    addTearDown(c.dispose);
    expect(c.read(masterVolumeProvider), 1.0);
  });

  test('lê o valor persistido', () async {
    final c = await _container(FakePlayer(), {'master_volume': 0.25});
    addTearDown(c.dispose);
    expect(c.read(masterVolumeProvider), 0.25);
  });

  test('setVolume persiste, aplica no player e atualiza o estado', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(masterVolumeProvider.notifier).setVolume(0.3);

    expect(c.read(masterVolumeProvider), 0.3);
    expect(fake.calls, contains('setVolume:0.3'));
    expect(c.read(sharedPreferencesProvider).getDouble('master_volume'), 0.3);
  });

  test('faz clamp entre 0 e 1', () async {
    final c = await _container(FakePlayer());
    addTearDown(c.dispose);
    final n = c.read(masterVolumeProvider.notifier);

    await n.setVolume(1.5);
    expect(c.read(masterVolumeProvider), 1.0);
    await n.setVolume(-1);
    expect(c.read(masterVolumeProvider), 0.0);
  });

  test('persist:false aplica mas não grava em disco', () async {
    final fake = FakePlayer();
    final c = await _container(fake);
    addTearDown(c.dispose);

    await c.read(masterVolumeProvider.notifier).setVolume(0.4, persist: false);

    expect(c.read(masterVolumeProvider), 0.4);
    expect(fake.calls, contains('setVolume:0.4'));
    expect(c.read(sharedPreferencesProvider).getDouble('master_volume'), isNull);
  });
}

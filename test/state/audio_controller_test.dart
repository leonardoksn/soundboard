import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/state/audio_controller.dart';

class FakeSoundPlayer implements SoundPlayer {
  final List<String> calls = [];
  @override
  Future<void> play(int id, String path, {bool loop = false}) async =>
      calls.add('play:$id:$path${loop ? ':loop' : ''}');
  @override
  Future<void> stop(int id) async => calls.add('stop:$id');
  @override
  Future<void> stopAll() async => calls.add('stopAll');
  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume:$volume');
  @override
  Future<void> dispose() async => calls.add('dispose');
  @override
  Stream<int> get onComplete => Stream<int>.empty();
}

void main() {
  test('play repassa id, caminho e loop para o player', () async {
    final fake = FakeSoundPlayer();
    final controller = AudioController(fake);

    await controller.play(1, '/a.mp3');
    await controller.play(2, '/b.mp3', loop: true);

    expect(fake.calls, ['play:1:/a.mp3', 'play:2:/b.mp3:loop']);
  });

  test('stop repassa o id; stopAll para tudo', () async {
    final fake = FakeSoundPlayer();
    final controller = AudioController(fake);
    await controller.stop(3);
    await controller.stopAll();
    expect(fake.calls, ['stop:3', 'stopAll']);
  });

  test('setVolume repassa para o player', () async {
    final fake = FakeSoundPlayer();
    await AudioController(fake).setVolume(0.5);
    expect(fake.calls, ['setVolume:0.5']);
  });

  test('dispose repassa para o player', () async {
    final fake = FakeSoundPlayer();
    await AudioController(fake).dispose();
    expect(fake.calls, contains('dispose'));
  });
}

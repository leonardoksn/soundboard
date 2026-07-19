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
  @override
  Stream<void> get onComplete => Stream<void>.empty();
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

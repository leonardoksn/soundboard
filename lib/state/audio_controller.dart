import 'package:audioplayers/audioplayers.dart';

abstract class SoundPlayer {
  Future<void> play(String path);
  Future<void> stop();
  Future<void> dispose();

  /// Emite um evento quando a reprodução do áudio atual termina naturalmente.
  Stream<void> get onComplete;
}

class AudioPlayersSoundPlayer implements SoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;
}

class AudioController {
  final SoundPlayer _player;

  AudioController(this._player);

  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(path);
  }

  Stream<void> get onComplete => _player.onComplete;

  Future<void> dispose() => _player.dispose();
}

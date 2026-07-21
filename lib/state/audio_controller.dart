import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

abstract class SoundPlayer {
  /// Toca [path] numa voz identificada por [id], permitindo sons simultâneos.
  Future<void> play(int id, String path, {bool loop = false});
  Future<void> stop(int id);
  Future<void> stopAll();

  /// Define o volume de reprodução (0.0 a 1.0) de todas as vozes.
  Future<void> setVolume(double volume);
  Future<void> dispose();

  /// Emite o id de uma voz que terminou naturalmente (não em loop).
  Stream<int> get onComplete;
}

class AudioPlayersSoundPlayer implements SoundPlayer {
  final Map<int, AudioPlayer> _players = {};
  final Map<int, StreamSubscription<void>> _subs = {};
  final StreamController<int> _complete = StreamController<int>.broadcast();
  double _volume = 1.0;

  /// Não solicita foco de áudio exclusivo: várias vozes tocam juntas (mix)
  /// sem que uma interrompa a outra. Conteúdo tratado como efeito sonoro.
  static final AudioContext _context = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  AudioPlayer _voice(int id) {
    return _players.putIfAbsent(id, () {
      final player = AudioPlayer();
      _subs[id] = player.onPlayerComplete.listen((_) => _complete.add(id));
      return player;
    });
  }

  @override
  Future<void> play(int id, String path, {bool loop = false}) async {
    final player = _voice(id);
    await player.setAudioContext(_context);
    await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await player.setVolume(_volume);
    await player.stop();
    await player.play(DeviceFileSource(path));
  }

  @override
  Future<void> stop(int id) async => _players[id]?.stop();

  @override
  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    for (final player in _players.values) {
      await player.setVolume(volume);
    }
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _subs.clear();
    await _complete.close();
  }

  @override
  Stream<int> get onComplete => _complete.stream;
}

class AudioController {
  final SoundPlayer _player;

  AudioController(this._player);

  Future<void> play(int id, String path, {bool loop = false}) =>
      _player.play(id, path, loop: loop);

  Future<void> stop(int id) => _player.stop(id);

  Future<void> stopAll() => _player.stopAll();

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Emite o id de uma voz que terminou naturalmente.
  Stream<int> get onComplete => _player.onComplete;

  Future<void> dispose() => _player.dispose();
}

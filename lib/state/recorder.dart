import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// Abstração de gravação de áudio (permite fakear nos testes).
abstract class Recorder {
  /// Solicita/verifica a permissão de microfone.
  Future<bool> hasPermission();

  /// Inicia a gravação gravando no arquivo [path].
  Future<void> start(String path);

  /// Encerra a gravação e retorna o caminho do arquivo gerado.
  Future<String?> stop();

  Future<void> dispose();
}

class RecordRecorder implements Recorder {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) =>
      _recorder.start(const RecordConfig(), path: path);

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}

final recorderProvider = Provider<Recorder>((ref) {
  final recorder = RecordRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_notifier.dart';
import 'providers.dart';

/// Volume master (0.0 a 1.0), persistido em shared_preferences.
class MasterVolumeNotifier extends Notifier<double> {
  static const _key = 'master_volume';

  @override
  double build() {
    return ref.watch(sharedPreferencesProvider).getDouble(_key) ?? 1.0;
  }

  /// Aplica o volume no player e atualiza o estado. Persiste em disco apenas
  /// quando [persist] for true — durante o arraste do fader use false para
  /// evitar I/O a cada frame; grave no `onChangeEnd`.
  Future<void> setVolume(double volume, {bool persist = true}) async {
    final v = volume.clamp(0.0, 1.0);
    state = v;
    await ref.read(audioControllerProvider).setVolume(v);
    if (persist) {
      await ref.read(sharedPreferencesProvider).setDouble(_key, v);
    }
  }
}

final masterVolumeProvider =
    NotifierProvider<MasterVolumeNotifier, double>(MasterVolumeNotifier.new);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../l10n/app_localizations.dart';
import '../models/sound.dart';
import '../state/playback_notifier.dart';
import '../state/providers.dart';
import '../state/volume_notifier.dart';
import 'add_edit_sound_sheet.dart';
import 'settings_sheet.dart';
import 'sound_button.dart';
import 'theme.dart';

class SoundboardScreen extends ConsumerWidget {
  const SoundboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final soundsAsync = ref.watch(soundsProvider);
    final playingIds = ref.watch(playingSoundsProvider);

    final sounds = soundsAsync.valueOrNull ?? const <Sound>[];
    // Visor: vazio → READY; 1 tocando → nome/cor; vários → contagem.
    String readout;
    Color readoutColor;
    if (playingIds.isEmpty) {
      readout = l10n.ready.toUpperCase();
      readoutColor = BoardColors.creamDim;
    } else if (playingIds.length == 1) {
      Sound? playing;
      for (final s in sounds) {
        if (s.id == playingIds.first) {
          playing = s;
          break;
        }
      }
      readout = (playing?.name ?? l10n.ready).toUpperCase();
      readoutColor =
          playing == null ? BoardColors.creamDim : Color(playing.color);
    } else {
      readout = '▶ ${playingIds.length}';
      readoutColor = BoardColors.rec;
    }

    return Scaffold(
      backgroundColor: BoardColors.chassis,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddEditSoundSheet(context),
        backgroundColor: BoardColors.padTop,
        foregroundColor: BoardColors.cream,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.addPad.toUpperCase(),
          style: BoardText.stencil.copyWith(color: BoardColors.cream),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Faceplate(readout: readout, readoutColor: readoutColor),
            Expanded(
              child: _Well(
                child: soundsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: BoardColors.cream),
                  ),
                  error: (e, _) => _Message(
                    message: l10n.loadError.toUpperCase(),
                    action: TextButton(
                      onPressed: () => ref.invalidate(soundsProvider),
                      child: Text(l10n.retry.toUpperCase(),
                          style: BoardText.stencil
                              .copyWith(color: BoardColors.rec)),
                    ),
                  ),
                  data: (sounds) {
                    if (sounds.isEmpty) {
                      return _Message(message: l10n.emptyState.toUpperCase());
                    }
                    return ReorderableGridView.count(
                      padding: const EdgeInsets.all(14),
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      onReorder: (oldIndex, newIndex) => ref
                          .read(soundsProvider.notifier)
                          .reorder(oldIndex, newIndex),
                      children: [
                        for (final sound in sounds)
                          SoundButton(
                            key: ValueKey(sound.id),
                            sound: sound,
                            isPlaying: playingIds.contains(sound.id),
                            onTap: () => ref
                                .read(playingSoundsProvider.notifier)
                                .toggle(sound),
                            onEdit: () =>
                                showAddEditSoundSheet(context, existing: sound),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placa frontal do equipamento: wordmark + faixa-assinatura 808 + visor.
class _Faceplate extends StatelessWidget {
  final String readout;
  final Color readoutColor;
  const _Faceplate({required this.readout, required this.readoutColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: BoardColors.chassis,
        border: Border(
          bottom: BorderSide(color: Colors.black45, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // LED de power
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BoardColors.rec,
                  boxShadow: [
                    BoxShadow(
                      color: BoardColors.rec.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              Text('RETRO BOARD', style: BoardText.wordmark),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                color: BoardColors.creamDim,
                tooltip: AppLocalizations.of(context).settings,
                visualDensity: VisualDensity.compact,
                onPressed: () => showSettingsSheet(context),
              ),
              const SizedBox(width: 4),
              _Readout(text: readout, color: readoutColor),
            ],
          ),
          const SizedBox(height: 10),
          const _LevelFader(),
          const SizedBox(height: 10),
          const _Band(),
        ],
      ),
    );
  }
}

/// Fader "LEVEL" — volume master, estilo mixer de hardware.
class _LevelFader extends ConsumerWidget {
  const _LevelFader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final volume = ref.watch(masterVolumeProvider);
    final notifier = ref.read(masterVolumeProvider.notifier);
    return Row(
      children: [
        Text(l10n.level.toUpperCase(), style: BoardText.stencil),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: BoardColors.rec,
              inactiveTrackColor: BoardColors.well,
              thumbColor: BoardColors.cream,
              overlayColor: BoardColors.rec.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: volume,
              // aplica ao vivo enquanto arrasta (sem gravar em disco)
              onChanged: (v) => notifier.setVolume(v, persist: false),
              // grava a preferência só ao soltar
              onChangeEnd: (v) => notifier.setVolume(v, persist: true),
            ),
          ),
        ),
      ],
    );
  }
}

/// Faixa horizontal de cores da TR-808 (vermelho → laranja → amarelo → osso).
class _Band extends StatelessWidget {
  const _Band();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Row(
        children: [
          for (final c in BoardColors.band)
            Expanded(child: Container(height: 6, color: c)),
        ],
      ),
    );
  }
}

/// Visor digital monoespaçado (nome do som tocando / READY).
class _Readout extends StatelessWidget {
  final String text;
  final Color color;
  const _Readout({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BoardColors.well,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black54),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: BoardText.readout.copyWith(color: color),
      ),
    );
  }
}

/// Poço escuro e recuado onde vive o grid de pads.
class _Well extends StatelessWidget {
  final Widget child;
  const _Well({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: BoardColors.well,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black54, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Mensagem centralizada em estilo serigrafia (estados vazio/erro).
class _Message extends StatelessWidget {
  final String message;
  final Widget? action;
  const _Message({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message,
                textAlign: TextAlign.center, style: BoardText.stencil),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

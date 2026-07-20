import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/sound.dart';
import '../state/providers.dart';
import 'sound_colors.dart';
import 'theme.dart';

/// Primeira cor da paleta (usada como default).
const int kSoundColorsFirst = 0xFFD8412F;

typedef FilePickerFn = Future<String?> Function();

final filePickerProvider = Provider<FilePickerFn>((ref) {
  return () async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    return result?.files.single.path;
  };
});

Future<void> showAddEditSoundSheet(
  BuildContext context, {
  Sound? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(child: _SoundForm(existing: existing)),
    ),
  );
}

class _SoundForm extends ConsumerStatefulWidget {
  final Sound? existing;
  const _SoundForm({this.existing});

  @override
  ConsumerState<_SoundForm> createState() => _SoundFormState();
}

class _SoundFormState extends ConsumerState<_SoundForm> {
  late final TextEditingController _nameController;
  late int _color;
  String? _pickedPath;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color ?? kSoundColorsFirst;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final path = await ref.read(filePickerProvider)();
    if (path != null) setState(() => _pickedPath = path);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(soundsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_isEditing) {
      final id = widget.existing!.id!;
      await notifier.rename(id, name);
      await notifier.changeColor(id, _color);
    } else {
      if (_pickedPath == null) return;
      try {
        await notifier.add(
            sourceFilePath: _pickedPath!, name: name, color: _color);
      } catch (_) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.importError)));
        return;
      }
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BoardColors.chassis,
        title: Text(l10n.deleteConfirm.toUpperCase(),
            style: BoardText.stencil.copyWith(
                color: BoardColors.cream, fontSize: 15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel.toUpperCase(), style: BoardText.stencil)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete.toUpperCase(),
                  style:
                      BoardText.stencil.copyWith(color: BoardColors.rec))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(soundsProvider.notifier).remove(widget.existing!.id!);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: BoardColors.chassis,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.black45, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: BoardColors.creamDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text((_isEditing ? l10n.editSound : l10n.newSound).toUpperCase(),
              style: BoardText.wordmark.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          if (!_isEditing)
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.audiotrack, color: BoardColors.cream),
              style: OutlinedButton.styleFrom(
                foregroundColor: BoardColors.cream,
                side: const BorderSide(color: BoardColors.creamDim),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: Text(
                (_pickedPath == null ? l10n.chooseFile : l10n.fileSelected)
                    .toUpperCase(),
                style: BoardText.stencil.copyWith(color: BoardColors.cream),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            style: const TextStyle(
                color: BoardColors.cream, fontFamily: 'Oswald'),
            cursorColor: BoardColors.rec,
            decoration: InputDecoration(
              labelText: l10n.name.toUpperCase(),
              labelStyle: BoardText.stencil,
              filled: true,
              fillColor: BoardColors.well,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.black54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: BoardColors.rec),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(l10n.padLed.toUpperCase(), style: BoardText.stencil),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in kSoundColors)
                _ColorChip(
                  color: Color(c),
                  selected: _color == c,
                  onTap: () => setState(() => _color = c),
                ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: BoardColors.rec,
              foregroundColor: BoardColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.save.toUpperCase(),
                style: BoardText.stencil.copyWith(
                    color: BoardColors.cream, fontSize: 14)),
          ),
          if (_isEditing)
            TextButton(
              onPressed: _delete,
              child: Text(l10n.delete.toUpperCase(),
                  style:
                      BoardText.stencil.copyWith(color: BoardColors.rec)),
            ),
        ],
      ),
    );
  }
}

/// Chip de cor em estilo LED: aceso (halo) quando selecionado.
class _ColorChip extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? BoardColors.cream : Colors.black45,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 10)]
              : null,
        ),
      ),
    );
  }
}

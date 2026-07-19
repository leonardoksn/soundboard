import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';
import '../state/providers.dart';
import 'sound_colors.dart';

/// Primeira cor da paleta (usada como default).
const int kSoundColorsFirst = 0xFFEF5350;

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
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SoundForm(existing: existing),
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
            const SnackBar(content: Text('não foi possível importar')));
        return;
      }
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir som?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? 'Editar som' : 'Novo som',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (!_isEditing)
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.audiotrack),
              label: Text(_pickedPath == null
                  ? 'Escolher arquivo'
                  : 'Arquivo selecionado'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final c in kSoundColors)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    backgroundColor: Color(c),
                    child: _color == c
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Salvar')),
          if (_isEditing)
            TextButton(
              onPressed: _delete,
              child:
                  const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

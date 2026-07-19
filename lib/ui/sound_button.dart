import 'package:flutter/material.dart';
import '../models/sound.dart';
import 'equalizer_bars.dart';

class SoundButton extends StatelessWidget {
  final Sound sound;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final bool isPlaying;

  const SoundButton({
    super.key,
    required this.sound,
    required this.onTap,
    required this.onEdit,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(sound.color);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  sound.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
            ),
            if (isPlaying)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: EqualizerBars(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
